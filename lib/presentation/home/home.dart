import 'package:events360_admin/core/assets/app_images.dart';
import 'package:events360_admin/core/constants/constants.dart';
import 'package:events360_admin/core/constants/permission_constants.dart';
import 'package:events360_admin/core/themes/app_colors.dart';
import 'package:events360_admin/core/widgets/app_snackbar.dart';
import 'package:events360_admin/infrastructure/supabase_service.dart';
import 'package:events360_admin/infrastructure/user_role_service.dart';
import 'package:events360_admin/presentation/auth/sign_in_screen.dart';
import 'package:events360_admin/presentation/event/event_form_screen.dart';
import 'package:events360_admin/presentation/event/event_management_screen.dart';
import 'package:events360_admin/presentation/event/ticket_management_screen.dart';
import 'package:events360_admin/presentation/organization/member_management_screen.dart';
import 'package:events360_admin/presentation/organization/organization_screen.dart';
import 'package:events360_admin/presentation/speaker/speaker_management_screen.dart';
import 'package:events360_admin/presentation/sponsor/sponsor_management_screen.dart';
import 'package:flutter/material.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;
  bool _isLoading = false;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    setState(() {
      _isLoading = true;
    });
    getOrganizationId();
    _loadStats();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> getOrganizationId() async {
    // Check if organization ID is already loaded
    if (SupabaseService.organizationId == null) {
      // If not, try to load it from storage
      await SupabaseService.loadOrganizationIdFromStorage();

      // If still null after loading from storage, redirect to login
      if (SupabaseService.organizationId == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Session expired. Please sign in again.')),
        );
        // Navigate to sign in screen
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SignInScreen()),
        );
        return;
      }
    }
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await SupabaseService().getDashboardStats();
      setState(() {
        _stats = stats;
      });
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading stats: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await SupabaseService().signOut();
      if (mounted) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SignInScreen()),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Events360 Admin',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      drawer: Drawer(
        elevation: 2,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: theme.primaryColor,
                image: const DecorationImage(
                  image: AssetImage(AppImages.appBgImg),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.white,
                    child: Icon(Icons.admin_panel_settings, size: 32),
                  ),
                  Constants.h16,
                  Text(
                    'Events360 Admin',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Event Management System',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              selected: _selectedIndex == 0,
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            // In the drawer navigation
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Events'),
              selected: _selectedIndex == 1,
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventManagementScreen(
                      organizationId: SupabaseService.organizationId ?? '',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Speakers'),
              selected: _selectedIndex == 2,
              onTap: () {
                setState(() {
                  _selectedIndex = 2;
                });
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SpeakerManagementScreen(
                      organizationId: SupabaseService.organizationId ?? '',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text('Sponsors'),
              selected: _selectedIndex == 3,
              onTap: () {
                setState(() {
                  _selectedIndex = 3;
                });
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SponsorManagementScreen(
                      organizationId: SupabaseService.organizationId ?? '',
                    ),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              selected: _selectedIndex == 4,
              onTap: () {
                setState(() {
                  _selectedIndex = 4;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: _signOut,
            ),
          ],
        ),
      ),
      body: _selectedIndex == 0
          ? _buildDashboard()
          : const Center(child: Text('Select an option from the drawer')),
    );
  }

  Widget _buildDashboard() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Welcome Back!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.blueV1,
                ),
                onPressed: _loadStats,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh Stats',
              ),
            ],
          ),
          Text(
            'Here\'s what\'s happening with your events',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Constants.h8,
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildStatCard(
                    context,
                    'View Organization',
                    _stats?['organizationCount'] ?? 1,
                    Icons.home_work_rounded,
                    AppColors.greyOffWhite,
                  ),
                  _buildStatCard(
                    context,
                    'My Events',
                    _stats?['eventCount'] ?? 0,
                    Icons.event,
                    AppColors.blue,
                  ),
                  _buildStatCard(
                    context,
                    'My Speakers',
                    _stats?['speakerCount'] ?? 0,
                    Icons.person,
                    AppColors.orange,
                  ),
                  _buildStatCard(
                    context,
                    'My Sponsors',
                    _stats?['sponsorCount'] ?? 0,
                    Icons.business,
                    AppColors.green,
                  ),
                  _buildStatCard(
                    context,
                    'Tickets',
                    _stats?['ticketCount'] ?? 0,
                    Icons.how_to_reg,
                    AppColors.yellow,
                  ),
                  _buildStatCard(
                    context,
                    'Registrations',
                    _stats?['registrationCount'] ?? 0,
                    Icons.how_to_reg,
                    AppColors.commonPink,
                  ),
                ],
              );
            },
          ),
          Constants.h32,
          Constants.h16,
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Constants.h8,
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildQuickActionButton(
                    'Add Members',
                    Icons.group_add_rounded,
                    () {
                      if (!UserRoleService.hasPermission(
                          PermissionConstants.MANAGE_MEMBERS)) {
                        showSnackBar(context,
                            "You don't have the necessary permissions to add members");
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MemberManagementScreen(
                            organizationId:
                                SupabaseService.organizationId ?? '',
                          ),
                        ),
                      );
                    },
                  ),
                  _buildQuickActionButton(
                    'Add Event',
                    Icons.event_note_rounded,
                    () {
                      if (!UserRoleService.hasPermission(
                          PermissionConstants.CREATE_EVENT)) {
                        showSnackBar(context,
                            "You don't have the necessary permissions to add events");
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EventFormScreen(
                            organizationId:
                                SupabaseService.organizationId ?? '',
                          ),
                        ),
                      );
                    },
                  ),
                  _buildQuickActionButton(
                    'Add Speaker',
                    Icons.person_add,
                    () {
                      if (!UserRoleService.hasPermission(
                          PermissionConstants.MANAGE_SPEAKERS)) {
                        showSnackBar(context,
                            "You don't have the necessary permissions to add speakers");
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SpeakerManagementScreen(
                            organizationId:
                                SupabaseService.organizationId ?? '',
                          ),
                        ),
                      );
                    },
                  ),
                  _buildQuickActionButton(
                    'Add Sponsor',
                    Icons.business,
                    () {
                      if (!UserRoleService.hasPermission(
                          PermissionConstants.MANAGE_SPONSORS)) {
                        showSnackBar(context,
                            "You don't have the necessary permissions to add sponsors");
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SponsorManagementScreen(
                            organizationId:
                                SupabaseService.organizationId ?? '',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: 280,
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 24,
              horizontal: 20,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  child: Icon(
                    icon,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    int value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          if (title == 'View Organization') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrganizationScreen(
                  organizationId: SupabaseService.organizationId ?? '',
                ),
              ),
            );
          }
          if (title == 'My Events') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EventManagementScreen(
                  organizationId: SupabaseService.organizationId ?? '',
                ),
              ),
            );
          } else if (title == 'My Speakers') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SpeakerManagementScreen(
                  organizationId: SupabaseService.organizationId ?? '',
                ),
              ),
            );
          } else if (title == 'My Sponsors') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SponsorManagementScreen(
                  organizationId: SupabaseService.organizationId ?? '',
                ),
              ),
            );
          } else if (title == 'Tickets') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TicketManagementScreen(),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withValues(alpha: 0.1),
                child: Icon(icon, color: color),
              ),
              Constants.h16,
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Constants.h8,
              Text(
                value.toString(),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
