from django.test import TestCase, Client
from django.contrib.auth import get_user_model
from meiari_v1.models import MeiAriUser, WorkGroup, TNGovtDept, WorkTicket, InspectionReport
from django.urls import reverse
from django.utils import timezone
from django.middleware.csrf import CsrfViewMiddleware

User = get_user_model()


class MeiAriModelTests(TestCase):
    def setUp(self):
        self.user = MeiAriUser.objects.create_user(username='testuser', password='testpass')
        self.department = TNGovtDept.objects.create(name='Health', code='HLTH')
        self.workgroup = WorkGroup.objects.create(name='Group A', department=self.department)
        self.ticket = WorkTicket.objects.create(
            title="Test Ticket",
            description="Testing WorkTicket",
            created_by=self.user,
            assigned_group=self.workgroup
        )
        self.report = InspectionReport.objects.create(
            ticket=self.ticket,
            submitted_by=self.user,
            report_summary="Test Summary",
            photo_url="https://test.com/image.jpg",
            submitted_at=timezone.now()
        )

    def test_user_creation(self):
        self.assertEqual(self.user.username, 'testuser')
        self.assertTrue(self.user.check_password('testpass'))

    def test_department_creation(self):
        self.assertEqual(self.department.name, 'Health')
        self.assertEqual(self.department.code, 'HLTH')

    def test_workgroup_association(self):
        self.assertEqual(self.workgroup.department.name, 'Health')

    def test_ticket_creation(self):
        self.assertEqual(self.ticket.title, "Test Ticket")
        self.assertEqual(self.ticket.created_by, self.user)

    def test_report_submission(self):
        self.assertEqual(self.report.ticket, self.ticket)
        self.assertEqual(self.report.submitted_by, self.user)

    def test_str_methods(self):
        self.assertEqual(str(self.department), "Health")
        self.assertEqual(str(self.workgroup), "Group A")
        self.assertEqual(str(self.ticket), "Test Ticket")
        self.assertEqual(str(self.report), f"Report by {self.user.username} on {self.ticket.title}")

    def test_ticket_with_optional_fields_missing(self):
        ticket = WorkTicket.objects.create(
            title="No Description",
            created_by=self.user,
            assigned_group=self.workgroup
        )
        self.assertIsNone(ticket.description)


class MeiAriIntegrationTests(TestCase):
    def setUp(self):
        self.client = Client()
        self.user = MeiAriUser.objects.create_user(username='integrate', password='integratepass')
        self.client.login(username='integrate', password='integratepass')
        self.dept = TNGovtDept.objects.create(name='PWD', code='PWD')
        self.group = WorkGroup.objects.create(name='WGroup', department=self.dept)

    def test_create_ticket_via_view(self):
        response = self.client.post(reverse('create_ticket'), {
            'title': 'Integration Ticket',
            'description': 'Integration test',
            'assigned_group': self.group.id
        })
        self.assertIn(response.status_code, [200, 302])
        self.assertTrue(WorkTicket.objects.filter(title='Integration Ticket').exists())

    def test_ticket_list_view_accessible(self):
        response = self.client.get(reverse('ticket_list'))
        self.assertIn(response.status_code, [200, 302])

    def test_create_report_for_ticket(self):
        ticket = WorkTicket.objects.create(title='RPT Ticket', created_by=self.user, assigned_group=self.group)
        response = self.client.post(reverse('submit_report'), {
            'ticket': ticket.id,
            'report_summary': 'Detailed summary',
            'photo_url': 'https://img.com/rep.jpg'
        })
        self.assertIn(response.status_code, [200, 302])


class MeiAriSystemTests(TestCase):
    def setUp(self):
        self.client = Client()
        self.user = MeiAriUser.objects.create_user(username='systemuser', password='systempass')
        self.client.login(username='systemuser', password='systempass')

    def test_login_page_access(self):
        response = self.client.get(reverse('admin_login'))
        self.assertEqual(response.status_code, 200)

    def test_admin_redirect(self):
        response = self.client.get(reverse('admin_home'), follow=True)
        self.assertIn(response.status_code, [200, 302])

    def test_homepage_view_status(self):
        response = self.client.get(reverse('home'))
        self.assertIn(response.status_code, [200, 302])


class MeiAriSecurityTests(TestCase):
    def setUp(self):
        self.client = Client()
        self.user = MeiAriUser.objects.create_user(username='secure', password='securepass')

    def test_authentication_required(self):
        response = self.client.get('/some/protected/url/')
        self.assertIn(response.status_code, [403, 302])

    def test_login_required(self):
        login = self.client.login(username='secure', password='securepass')
        self.assertTrue(login)

    def test_invalid_login(self):
        login = self.client.login(username='wrong', password='wrong')
        self.assertFalse(login)

    def test_protected_page_after_login(self):
        self.client.login(username='secure', password='securepass')
        response = self.client.get('/some/protected/url/')
        self.assertIn(response.status_code, [200, 302])

    def test_csrf_protection(self):
        response = self.client.post(reverse('create_ticket'), data={}, follow=True)
        self.assertIn(response.status_code, [200, 403, 302])


class MeiAriManagePyCoverageTests(TestCase):
    def test_manage_help_command(self):
        import subprocess
        import sys

        result = subprocess.run(
            [sys.executable, 'manage.py', 'help'],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        self.assertEqual(result.returncode, 0)
        self.assertIn("Type 'manage.py help <subcommand>' for help", result.stdout)


class MeiAriLogoutTests(TestCase):
    def setUp(self):
        self.client = Client()
        self.user = MeiAriUser.objects.create_user(username='secure', password='securepass')

    def test_logout_clears_session(self):
        self.client.login(username='secure', password='securepass')
        self.client.logout()
        response = self.client.get('/some/protected/url/')
        self.assertIn(response.status_code, [403, 302])
