// // ignore_for_file: prefer_final_fields

// import 'package:flutter/material.dart';
// import 'package:flutter_quill/flutter_quill.dart';
// import 'package:rich_editor/rich_editor.dart';

// // ignore: must_be_immutable
// class DevEditor extends StatelessWidget {
//   final GlobalKey<RichEditorState> keyEditor = GlobalKey();
//   QuillController _controller = QuillController.basic();

//   DevEditor({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Column(
//           children: [
//             QuillToolbar.simple(
//               configurations: QuillSimpleToolbarConfigurations(
//                 controller: _controller,
//                 sharedConfigurations: const QuillSharedConfigurations(
//                   locale: Locale('de'),
//                 ),
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: QuillEditor.basic(
//                 configurations: QuillEditorConfigurations(
//                   placeholder: "Type here..",
//                   controller: _controller,
//                   autoFocus: true,
//                   sharedConfigurations: const QuillSharedConfigurations(
//                     locale: Locale('de'),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
