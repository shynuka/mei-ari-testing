import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:meiarife/screens/geo_locator/get_location_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SectionFormScreen extends StatefulWidget {
  final String departmentId;

  const SectionFormScreen({super.key, required this.departmentId});

  @override
  _SectionFormScreenState createState() => _SectionFormScreenState();
}

class _SectionFormScreenState extends State<SectionFormScreen> {
  List<dynamic> sections = [];
  int currentSectionIndex = 0;
  bool isLoading = true;
  String errorMessage = '';
  Map<String, Map<String, String>> formResponses = {};
  List<dynamic> fields = [];
  Map<String, TextEditingController> textControllers = {};
  Map<String, int?> selectedOptions = {};
  Map<String, String?> fieldErrors = {};

  @override
  void initState() {
    super.initState();
    fetchSections();
  }

  Future<void> fetchSections() async {
    final url =
        'https://meiari-qns-be.onrender.com/api/surveys/sections/${widget.departmentId}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          sections = data;
          if (sections.isNotEmpty) {
            fetchFields(sections[currentSectionIndex]['_id']);
          }
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load sections';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> fetchFields(String sectionId) async {
    final url =
        'https://meiari-qns-be.onrender.com/api/surveys/${widget.departmentId}/sections/$sectionId';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          fields = data['fields'];
          textControllers.clear();
          selectedOptions.clear();
          fieldErrors.clear();

          for (var field in fields) {
            if (isFirstOrLastSection()) {
              textControllers[field['key']] = TextEditingController();
            } else {
              selectedOptions[field['key']] = null;
            }
            fieldErrors[field['key']] = null;
          }
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load form questions';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
      });
    }
  }

  bool isFirstOrLastSection() {
    return currentSectionIndex == 0 ||
        currentSectionIndex == sections.length - 1;
  }

  bool validateForm() {
    bool isValid = true;
    setState(() {
      fieldErrors.clear();
      for (var field in fields) {
        if (isFirstOrLastSection()) {
          if (textControllers[field['key']]!.text.isEmpty) {
            fieldErrors[field['key']] = "This field is required";
            isValid = false;
          }
        } else {
          if (selectedOptions[field['key']] == null) {
            fieldErrors[field['key']] = "Please select a value from 1 to 5";
            isValid = false;
          }
        }
      }
    });
    return isValid;
  }

  void nextSection() {
    if (!validateForm()) return;

    // Save responses for the current section
    formResponses[sections[currentSectionIndex]['_id']] = {
      for (var field in fields)
        field['key']:
            isFirstOrLastSection()
                ? textControllers[field['key']]!.text
                : selectedOptions[field['key']]?.toString() ?? "",
    };

    // Ensure we do not exceed the list length
    if (currentSectionIndex < sections.length - 1) {
      setState(() {
        currentSectionIndex++;
        fetchFields(sections[currentSectionIndex]['_id']);
      });
    } else {
      submitForm();
    }
  }

  void submitForm() async {
    if (!validateForm()) return;

    List<Map<String, dynamic>> structuredResponses = [];

    for (var section in sections) {
      String sectionId = section['_id'];
      String sectionName = section['name'];

      if (formResponses.containsKey(sectionId)) {
        structuredResponses.add({
          "sectionId": sectionId,
          "sectionName": sectionName,
          "questions":
              formResponses[sectionId]!.entries.map((entry) {
                return {"question": entry.key, "answer": entry.value};
              }).toList(),
        });
      }
    }

    prettyPrintJson(structuredResponses);

    final url =
        'http://192.168.107.231:8000/api/v1/generate-and-upload-report/';

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessId = prefs.getString('access_id');
      final departmentName = prefs.getString('department_name') ?? '';
      final subDepartmentName = prefs.getString('sub_department_name') ?? '';
      final subDeptOfficeName = prefs.getString('sub_dept_office_name') ?? '';

      if (accessId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error: Access ID not found. Please login again."),
          ),
        );
        return;
      }

      var cubit = GetLocationCubit.get(context);

      // ✅ Ensure location services are initialized
      await cubit.initLocation();

      // ✅ Get location before proceeding
      Position? position = await cubit.getLocation();

      if (position == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: Unable to fetch location. Please try again."),
          ),
        );
        return;
      }

      // ✅ Get country after location is retrieved
      Placemark? place = await cubit.getCountry();

      if (place == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: Unable to fetch location details.")),
        );
        return;
      }

      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "departmentId": widget.departmentId,
          "accessId": accessId,
          "responses": structuredResponses,
          "departmentName": departmentName,
          "subDepartmentName": subDepartmentName,
          "subDeptOfficeName": subDeptOfficeName,
          "location": {
            "latitude": position.latitude,
            "longitude": position.longitude,
            "country": place.country ?? "Unknown",
            "city": place.locality ?? "Unknown",
          },
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Form Submitted Successfully!")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Submission Failed! Try again.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Section"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              sections[currentSectionIndex]['name'],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: fields.length,
                itemBuilder: (context, index) {
                  var field = fields[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child:
                          isFirstOrLastSection()
                              ? TextField(
                                controller: textControllers[field['key']],
                                decoration: InputDecoration(
                                  labelText: field['key'],
                                  errorText: fieldErrors[field['key']],
                                  border: const OutlineInputBorder(),
                                ),
                              )
                              : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    field['key'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: List.generate(5, (index) {
                                      return Column(
                                        children: [
                                          Radio(
                                            value: index + 1,
                                            groupValue:
                                                selectedOptions[field['key']],
                                            onChanged:
                                                (value) => setState(
                                                  () =>
                                                      selectedOptions[field['key']] =
                                                          value,
                                                ),
                                          ),
                                          Text("${index + 1}"),
                                        ],
                                      );
                                    }),
                                  ),
                                ],
                              ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: nextSection,
                child: Text(
                  currentSectionIndex == sections.length - 1
                      ? "Submit"
                      : "Next",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String toRoman(int number) {
  const numerals = [
    ["I", "IV", "V", "IX"],
    ["X", "XL", "L", "XC"],
    ["C", "CD", "D", "CM"],
    ["M", "", "", ""],
  ];
  String result = "";
  int i = 0;
  while (number > 0) {
    int digit = number % 10;
    if (digit > 0) {
      result = numerals[i][digit - 1] + result;
    }
    number ~/= 10;
    i++;
  }
  return result;
}

void prettyPrintJson(dynamic jsonData) {
  const int chunkSize = 800;
  String jsonString = jsonEncode(jsonData);
  for (int i = 0; i < jsonString.length; i += chunkSize) {
    print(
      jsonString.substring(
        i,
        i + chunkSize > jsonString.length ? jsonString.length : i + chunkSize,
      ),
    );
  }
}
