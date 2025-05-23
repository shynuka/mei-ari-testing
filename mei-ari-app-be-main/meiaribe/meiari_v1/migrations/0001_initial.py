# Generated by Django 5.2 on 2025-04-09 10:08

import django.db.models.deletion
import uuid
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
    ]

    operations = [
        migrations.CreateModel(
            name='MeiAriUser',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('cug_phone_number', models.CharField(max_length=20)),
                ('cug_email_address', models.EmailField(max_length=254, unique=True)),
                ('password', models.CharField(max_length=255)),
                ('access_list', models.TextField()),
                ('role', models.CharField(choices=[('Inspection_Cell_Officer', 'Inspection_Cell_Officer'), ('Inspection_Cell_Head', 'Inspection_Cell_Head'), ('Inspection_Cell_Admin', 'Inspection_Cell_Admin')], max_length=50)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('modified_at', models.DateTimeField(auto_now=True)),
            ],
        ),
        migrations.CreateModel(
            name='SubDeptOfficeDetails',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('sub_dept_office_location', models.CharField(max_length=255)),
                ('sub_dept_street_address', models.TextField()),
                ('sub_dept_district', models.CharField(max_length=255)),
                ('sub_dept_taluk', models.CharField(max_length=255)),
                ('sub_dept_access_code', models.CharField(max_length=100, unique=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
            ],
        ),
        migrations.CreateModel(
            name='TNGovtDept',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('department_name', models.CharField(max_length=255)),
                ('level', models.CharField(max_length=50)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('modified_at', models.DateTimeField(auto_now=True)),
            ],
        ),
        migrations.CreateModel(
            name='WorkGroupTicket',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('ticket_code', models.CharField(max_length=100, unique=True)),
                ('ticket_title', models.CharField(max_length=255)),
                ('ticket_description', models.TextField()),
                ('ticket_status', models.CharField(choices=[('Open', 'Open'), ('InProgress', 'InProgress'), ('Closed', 'Closed')], max_length=50)),
                ('ticket_type', models.CharField(choices=[('CustomTemplate', 'CustomTemplate'), ('PreBuiltTemplate', 'PreBuiltTemplate'), ('TaskAssign', 'TaskAssign')], max_length=50)),
                ('ticket_priority', models.CharField(choices=[('High', 'High'), ('Medium', 'Medium'), ('Low', 'Low')], max_length=50)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
            ],
        ),
        migrations.CreateModel(
            name='MeiAriUserBioData',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('user_name', models.CharField(max_length=255)),
                ('active', models.BooleanField(default=True)),
                ('first_name', models.CharField(max_length=255)),
                ('last_name', models.CharField(max_length=255)),
                ('date_of_birth', models.DateField()),
                ('alternative_email_address', models.EmailField(max_length=254)),
                ('access_id', models.CharField(max_length=20, unique=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('modified_at', models.DateTimeField(auto_now=True)),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='meiari_v1.meiariuser')),
            ],
        ),
        migrations.CreateModel(
            name='OTPTable',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('otp', models.CharField(max_length=4)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('modified_at', models.DateTimeField(auto_now=True)),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='meiari_v1.meiariuser')),
            ],
        ),
        migrations.AddField(
            model_name='meiariuser',
            name='sub_dept_office_id',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='meiari_v1.subdeptofficedetails'),
        ),
        migrations.AddField(
            model_name='meiariuser',
            name='dept_id',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='meiari_v1.tngovtdept'),
        ),
        migrations.CreateModel(
            name='TNGovtDeptContact',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('cug_minister_email', models.EmailField(max_length=254)),
                ('cug_minister_phone_number', models.CharField(max_length=20)),
                ('minister_name', models.CharField(max_length=255)),
                ('stg_email', models.EmailField(max_length=254)),
                ('stg_phone_number', models.CharField(max_length=20)),
                ('stg_name', models.CharField(max_length=255)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('modified_at', models.DateTimeField(auto_now=True)),
                ('department_id', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='meiari_v1.tngovtdept')),
            ],
        ),
        migrations.CreateModel(
            name='TNGovtSubDept',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('sub_department_name', models.CharField(max_length=255)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('modified_at', models.DateTimeField(auto_now=True)),
                ('department', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='meiari_v1.tngovtdept')),
            ],
        ),
        migrations.AddField(
            model_name='subdeptofficedetails',
            name='sub_dept',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='meiari_v1.tngovtsubdept'),
        ),
        migrations.CreateModel(
            name='SubDeptDetails',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('sub_dept_office', models.CharField(max_length=255)),
                ('sub_dept_hod', models.CharField(max_length=255)),
                ('sub_dept_cug_email', models.EmailField(max_length=254)),
                ('sub_dept_cug_phone_number', models.CharField(max_length=20)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('modified_at', models.DateTimeField(auto_now=True)),
                ('sub_dept', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='meiari_v1.tngovtsubdept')),
            ],
        ),
        migrations.AddField(
            model_name='meiariuser',
            name='sub_dept_id',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='meiari_v1.tngovtsubdept'),
        ),
        migrations.CreateModel(
            name='WorkGroup',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('group_name', models.CharField(max_length=255)),
                ('is_active', models.BooleanField(default=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('modified_at', models.DateTimeField(auto_now=True)),
                ('sub_dept_office', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='meiari_v1.subdeptofficedetails')),
            ],
        ),
        migrations.AddField(
            model_name='meiariuser',
            name='groups',
            field=models.ManyToManyField(blank=True, related_name='users', to='meiari_v1.workgroup'),
        ),
        migrations.CreateModel(
            name='WorkGroupDetails',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('group_description', models.TextField()),
                ('group_photo', models.ImageField(blank=True, null=True, upload_to='group_photos/')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('modified_at', models.DateTimeField(auto_now=True)),
                ('work_group', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='meiari_v1.workgroup')),
            ],
        ),
        migrations.CreateModel(
            name='WorkGroupMember',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('user_id', models.UUIDField()),
                ('role_name', models.CharField(max_length=100)),
                ('joined_at', models.DateTimeField(auto_now_add=True)),
                ('left_at', models.DateTimeField(blank=True, null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('modified_at', models.DateTimeField(auto_now=True)),
                ('work_group', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='meiari_v1.workgroup')),
            ],
        ),
    ]
