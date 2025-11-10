import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/institution_model.dart';
import '../../models/location_model.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../services/firestore_service.dart';

class InstitutionProfileScreen extends StatefulWidget {
  const InstitutionProfileScreen({super.key});

  @override
  State<InstitutionProfileScreen> createState() => _InstitutionProfileScreenState();
}

class _InstitutionProfileScreenState extends State<InstitutionProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // Form controllers
  final _institutionNameController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _numberOfBeneficiariesController = TextEditingController();
  final _websiteController = TextEditingController();

  // Institution type
  String _institutionType = 'school';

  // Location
  String _selectedProvince = '';
  String _selectedDistrict = '';
  String _selectedSector = '';
  String _selectedCell = '';
  String _selectedVillage = '';

  // Nutritional requirements
  final _monthlyRequirementController = TextEditingController();
  bool _requiresIronFortified = true;
  final _varietyPreferenceController = TextEditingController();
  final _dietaryNotesController = TextEditingController();

  // Procurement info
  String _budgetCycle = 'quarterly';
  final _budgetAmountController = TextEditingController();
  String _procurementMethod = 'tender';
  final _paymentTermsController = TextEditingController();

  @override
  void dispose() {
    _institutionNameController.dispose();
    _registrationNumberController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _numberOfBeneficiariesController.dispose();
    _websiteController.dispose();
    _monthlyRequirementController.dispose();
    _varietyPreferenceController.dispose();
    _dietaryNotesController.dispose();
    _budgetAmountController.dispose();
    _paymentTermsController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userModel?.id ?? '';

      NutritionalRequirements? nutritionalRequirements;
      if (_monthlyRequirementController.text.isNotEmpty) {
        nutritionalRequirements = NutritionalRequirements(
          monthlyBeanRequirement: double.parse(_monthlyRequirementController.text),
          requiresIronFortified: _requiresIronFortified,
          specificVarietyPreference: _varietyPreferenceController.text.isNotEmpty
              ? _varietyPreferenceController.text
              : null,
          dietaryNotes: _dietaryNotesController.text.isNotEmpty
              ? _dietaryNotesController.text
              : null,
        );
      }

      ProcurementInfo? procurementInfo = ProcurementInfo(
        budgetCycle: _budgetCycle,
        budgetAmount: _budgetAmountController.text.isNotEmpty
            ? double.tryParse(_budgetAmountController.text)
            : null,
        procurementMethod: _procurementMethod,
        preferredPaymentTerms: _paymentTermsController.text.isNotEmpty
            ? _paymentTermsController.text
            : null,
      );

      final profile = InstitutionModel(
        id: '',
        userId: userId,
        institutionName: _institutionNameController.text.trim(),
        institutionType: _institutionType,
        registrationNumber: _registrationNumberController.text.trim(),
        location: LocationModel(
          district: _selectedDistrict,
          sector: _selectedSector,
          cell: _selectedCell,
        ),
        contactPerson: _contactPersonController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        nutritionalRequirements: nutritionalRequirements,
        procurementInfo: procurementInfo,
        numberOfBeneficiaries: _numberOfBeneficiariesController.text.isNotEmpty
            ? int.tryParse(_numberOfBeneficiariesController.text)
            : null,
        website: _websiteController.text.isNotEmpty 
            ? _websiteController.text.trim() 
            : null,
        createdAt: DateTime.now(),
        isActive: true,
      );

      await FirestoreService().createInstitution(profile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile created! Awaiting admin verification.'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Institution Profile'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Progress indicator
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: List.generate(3, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? AppTheme.primaryColor
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildBasicInfoPage(),
                  _buildLocationPage(),
                  _buildRequirementsPage(),
                ],
              ),
            ),

            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : (_currentPage == 2 ? _submitProfile : _nextPage),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_currentPage == 2 ? 'Submit' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Institution Information',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Schools and hospitals purchasing iron-biofortified beans',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 24),

          DropdownButtonFormField<String>(
            value: _institutionType,
            decoration: const InputDecoration(
              labelText: 'Institution Type *',
              prefixIcon: Icon(Icons.business),
            ),
            items: [
              const DropdownMenuItem(value: 'school', child: Text('School')),
              const DropdownMenuItem(value: 'hospital', child: Text('Hospital')),
              const DropdownMenuItem(value: 'other', child: Text('Other')),
            ],
            onChanged: (value) {
              setState(() => _institutionType = value ?? 'school');
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _institutionNameController,
            decoration: const InputDecoration(
              labelText: 'Institution Name *',
              hintText: 'e.g., GS Kigali Primary School',
              prefixIcon: Icon(Icons.school),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Institution name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _registrationNumberController,
            decoration: const InputDecoration(
              labelText: 'Registration Number *',
              hintText: 'Official registration number',
              prefixIcon: Icon(Icons.assignment),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Registration number is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _numberOfBeneficiariesController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: _institutionType == 'school' 
                  ? 'Number of Students' 
                  : 'Number of Patients',
              hintText: 'e.g., 500',
              prefixIcon: const Icon(Icons.people),
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _contactPersonController,
            decoration: const InputDecoration(
              labelText: 'Contact Person *',
              hintText: 'Director or Manager name',
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Contact person is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number *',
              hintText: '+250 XXX XXX XXX',
              prefixIcon: Icon(Icons.phone),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Phone number is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email *',
              hintText: 'institution@example.com',
              prefixIcon: Icon(Icons.email),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email is required';
              }
              if (!value.contains('@')) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _websiteController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Website',
              hintText: 'https://example.com',
              prefixIcon: Icon(Icons.language),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location Details',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Provide your institution\'s physical location',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 24),

          DropdownButtonFormField<String>(
            value: _selectedProvince.isEmpty ? null : _selectedProvince,
            decoration: const InputDecoration(
              labelText: 'Province *',
              prefixIcon: Icon(Icons.location_city),
            ),
            items: ['Kigali', 'Northern', 'Southern', 'Eastern', 'Western']
                .map((province) => DropdownMenuItem(
                      value: province,
                      child: Text(province),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() => _selectedProvince = value ?? '');
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Province is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            decoration: const InputDecoration(
              labelText: 'District *',
              prefixIcon: Icon(Icons.location_on),
            ),
            onChanged: (value) => _selectedDistrict = value,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'District is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Sector *',
              prefixIcon: Icon(Icons.apartment),
            ),
            onChanged: (value) => _selectedSector = value,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Sector is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Cell',
              prefixIcon: Icon(Icons.home_work),
            ),
            onChanged: (value) => _selectedCell = value,
          ),
          const SizedBox(height: 16),

          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Village',
              prefixIcon: Icon(Icons.home),
            ),
            onChanged: (value) => _selectedVillage = value,
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nutritional Requirements & Procurement',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),

          Text(
            'Nutritional Needs',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _monthlyRequirementController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Monthly Bean Requirement (kg)',
              hintText: 'e.g., 500',
              prefixIcon: Icon(Icons.restaurant),
            ),
          ),
          const SizedBox(height: 16),

          SwitchListTile(
            title: const Text('Requires Iron-Biofortified Beans'),
            subtitle: const Text('High iron content for better nutrition'),
            value: _requiresIronFortified,
            onChanged: (value) {
              setState(() => _requiresIronFortified = value);
            },
            activeColor: AppTheme.primaryColor,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _varietyPreferenceController,
            decoration: const InputDecoration(
              labelText: 'Specific Variety Preference',
              hintText: 'e.g., MAC 42',
              prefixIcon: Icon(Icons.eco),
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _dietaryNotesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Dietary Notes',
              hintText: 'Any special dietary requirements or notes',
              prefixIcon: Icon(Icons.note),
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'Procurement Information',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _budgetCycle,
            decoration: const InputDecoration(
              labelText: 'Budget Cycle',
              prefixIcon: Icon(Icons.calendar_today),
            ),
            items: const [
              DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
              DropdownMenuItem(value: 'quarterly', child: Text('Quarterly')),
              DropdownMenuItem(value: 'annually', child: Text('Annually')),
            ],
            onChanged: (value) {
              setState(() => _budgetCycle = value ?? 'quarterly');
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _budgetAmountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Budget Amount (RWF)',
              hintText: 'e.g., 5000000',
              prefixIcon: Icon(Icons.attach_money),
            ),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _procurementMethod,
            decoration: const InputDecoration(
              labelText: 'Procurement Method',
              prefixIcon: Icon(Icons.shopping_cart),
            ),
            items: const [
              DropdownMenuItem(value: 'tender', child: Text('Public Tender')),
              DropdownMenuItem(value: 'direct', child: Text('Direct Purchase')),
              DropdownMenuItem(value: 'framework', child: Text('Framework Agreement')),
            ],
            onChanged: (value) {
              setState(() => _procurementMethod = value ?? 'tender');
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _paymentTermsController,
            decoration: const InputDecoration(
              labelText: 'Preferred Payment Terms',
              hintText: 'e.g., Net 30 days',
              prefixIcon: Icon(Icons.payment),
            ),
          ),
          const SizedBox(height: 24),

          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.health_and_safety, color: Colors.green, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Fighting Malnutrition',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Iron-biofortified beans help reduce iron deficiency anemia in Rwanda',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
