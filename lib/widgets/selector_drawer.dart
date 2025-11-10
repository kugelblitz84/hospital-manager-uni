import 'package:flutter/material.dart';
import 'package:medicare/Providers/doctorProvider.dart' as doctor_provider;
import 'package:medicare/Providers/patientPrivider.dart' as patient_provider;
import 'package:medicare/theme/app_theme.dart';

class SelectorDrawer extends StatefulWidget {
  const SelectorDrawer({
    super.key,
    required this.initialIndex,
    required this.doctors,
    required this.patients,
    required this.onDoctorSelect,
    required this.onPatientSelect,
    required this.selectedDoctorId,
    required this.selectedPatientId,
  });

  final int initialIndex;
  final List<doctor_provider.doctor> doctors;
  final List<patient_provider.patient> patients;
  final void Function(String?) onDoctorSelect;
  final void Function(String?) onPatientSelect;
  final String? selectedDoctorId;
  final String? selectedPatientId;

  @override
  State<SelectorDrawer> createState() => _SelectorDrawerState();
}

class _SelectorDrawerState extends State<SelectorDrawer>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedSpeciality;

  @override
  void initState() {
    super.initState();
    final initialTab = widget.initialIndex.clamp(0, 1).toInt();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: initialTab,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) {
        setState(() {
          _searchQuery = '';
          _searchController.clear();
          if (_tabController.index != 0) {
            _selectedSpeciality = null;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<doctor_provider.doctor> get _filteredDoctors {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty && _selectedSpeciality == null) {
      return widget.doctors;
    }
    return widget.doctors.where((doc) {
      final name = (doc.name ?? '').toLowerCase();
      final email = (doc.email ?? '').toLowerCase();
      final speciality = (doc.speciality ?? '').toLowerCase();
      final matchesQuery = query.isEmpty
          ? true
          : name.contains(query) ||
                email.contains(query) ||
                speciality.contains(query);
      final targetSpeciality = _selectedSpeciality?.toLowerCase();
      final matchesSpeciality =
          targetSpeciality == null ||
          (speciality.isNotEmpty && speciality == targetSpeciality);
      return matchesQuery && matchesSpeciality;
    }).toList();
  }

  List<patient_provider.patient> get _filteredPatients {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.patients;
    }
    return widget.patients.where((patient) {
      final name = (patient.name ?? '').toLowerCase();
      final email = (patient.email ?? '').toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();
  }

  List<String> get _specialityFilters {
    final seen = <String>{};
    final filters = <String>[];
    for (final doc in widget.doctors) {
      final speciality = (doc.speciality ?? '').trim();
      if (speciality.isEmpty) {
        continue;
      }
      final key = speciality.toLowerCase();
      if (seen.add(key)) {
        filters.add(speciality);
      }
    }
    filters.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return filters;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    final double drawerWidth = screenWidth < 420
        ? screenWidth * 0.9
        : screenWidth > 980
        ? 520
        : screenWidth * 0.55;
    final placeholder = _tabController.index == 0
        ? 'Search doctors by name, email, or speciality'
        : 'Search patients by name or email';
    final trimmedQuery = _searchQuery.trim();
    final specialities = _tabController.index == 0
        ? _specialityFilters
        : const [];
    final hasSpecialityFilters = specialities.isNotEmpty;

    return Drawer(
      width: drawerWidth,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.people_alt_rounded,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Browse roster',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: placeholder,
                  suffixIcon: trimmedQuery.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                            if (_tabController.index == 0) {
                              _selectedSpeciality = null;
                            }
                          }),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
              ),
            ),
            if (_tabController.index == 0 && hasSpecialityFilters)
              SizedBox(
                height: 48,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: specialities.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final isSelected = _selectedSpeciality == null;
                      return ChoiceChip(
                        label: const Text('All specialities'),
                        selected: isSelected,
                        onSelected: (value) {
                          if (value && !isSelected) {
                            setState(() => _selectedSpeciality = null);
                          }
                        },
                      );
                    }
                    final speciality = specialities[index - 1];
                    final isSelected = _selectedSpeciality == speciality;
                    return ChoiceChip(
                      label: Text(speciality),
                      selected: isSelected,
                      onSelected: (value) {
                        setState(() {
                          _selectedSpeciality = value ? speciality : null;
                        });
                      },
                    );
                  },
                ),
              ),
            if (_tabController.index == 0 && hasSpecialityFilters)
              const SizedBox(height: 4),
            TabBar(
              controller: _tabController,
              labelColor: theme.colorScheme.primary,
              indicatorColor: theme.colorScheme.primary,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: const [
                Tab(text: 'Doctors'),
                Tab(text: 'Patients'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _DrawerListView(
                    emptyLabel: trimmedQuery.isEmpty
                        ? (_selectedSpeciality == null
                              ? 'No doctors found.'
                              : 'No doctors in the selected speciality.')
                        : 'No doctors match "$trimmedQuery".',
                    children: _filteredDoctors
                        .map(
                          (doc) => _DoctorCard(
                            doctor: doc,
                            onSelect: () => widget.onDoctorSelect(doc.uid),
                            isSelected: widget.selectedDoctorId == doc.uid,
                          ),
                        )
                        .toList(),
                  ),
                  _DrawerListView(
                    emptyLabel: trimmedQuery.isEmpty
                        ? 'No patients found.'
                        : 'No patients match "$trimmedQuery".',
                    children: _filteredPatients
                        .map(
                          (patient) => _PatientCard(
                            patient: patient,
                            onSelect: () => widget.onPatientSelect(patient.uid),
                            isSelected: widget.selectedPatientId == patient.uid,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerListView extends StatelessWidget {
  const _DrawerListView({required this.children, required this.emptyLabel});

  final List<Widget> children;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return Center(
        child: Text(
          emptyLabel,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) => children[index],
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemCount: children.length,
    );
  }
}

class _DoctorCard extends StatelessWidget {
  const _DoctorCard({
    required this.doctor,
    required this.onSelect,
    required this.isSelected,
  });

  final doctor_provider.doctor doctor;
  final VoidCallback onSelect;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final speciality = doctor.speciality?.isNotEmpty == true
        ? doctor.speciality!
        : 'Speciality not set';
    return Card(
      color: isSelected ? AppColors.secondary.withOpacity(0.08) : null,
      child: ExpansionTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.secondary,
          child: Icon(Icons.medical_services_outlined, color: Colors.white),
        ),
        title: Text(doctor.name ?? doctor.email ?? 'Unnamed doctor'),
        subtitle: Text(speciality),
        childrenPadding: const EdgeInsets.only(bottom: 16),
        children: [
          _DrawerInfoRow(label: 'Email', value: doctor.email),
          _DrawerInfoRow(label: 'Speciality', value: doctor.speciality),
          _DrawerInfoRow(label: 'Joined', value: doctor.createdAt),
          if ((doctor.certifications ?? []).isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Certifications',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: doctor.certifications!
                        .map(
                          (cert) => Chip(
                            label: Text(cert),
                            backgroundColor: AppColors.secondary.withOpacity(
                              0.1,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: doctor.uid == null ? null : onSelect,
                icon: Icon(
                  isSelected ? Icons.check_circle : Icons.event_available,
                ),
                label: Text(isSelected ? 'Selected' : 'Select doctor'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  const _PatientCard({
    required this.patient,
    required this.onSelect,
    required this.isSelected,
  });

  final patient_provider.patient patient;
  final VoidCallback onSelect;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isSelected ? AppColors.secondary.withOpacity(0.08) : null,
      child: ExpansionTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Icon(Icons.person_outline, color: Colors.white),
        ),
        title: Text(patient.name ?? patient.email ?? 'Unnamed patient'),
        subtitle: Text(patient.email ?? 'Email not provided'),
        childrenPadding: const EdgeInsets.only(bottom: 16),
        children: [
          _DrawerInfoRow(label: 'Email', value: patient.email),
          _DrawerInfoRow(label: 'Phone', value: patient.phone),
          _DrawerInfoRow(label: 'Age', value: patient.age),
          _DrawerInfoRow(label: 'Address', value: patient.address),
          _DrawerInfoRow(label: 'Medical notes', value: patient.medicalHistory),
          _DrawerInfoRow(label: 'Registered', value: patient.createdAt),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: patient.uid == null ? null : onSelect,
                icon: Icon(
                  isSelected ? Icons.check_circle : Icons.event_available,
                ),
                label: Text(isSelected ? 'Selected' : 'Select patient'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerInfoRow extends StatelessWidget {
  const _DrawerInfoRow({required this.label, this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final displayValue = (value != null && value!.trim().isNotEmpty)
        ? value!.trim()
        : 'Not provided';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Text(displayValue, style: textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
