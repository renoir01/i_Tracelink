import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/cooperative_model.dart';
import '../../models/location_model.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../services/firestore_service.dart';

class CooperativeProfileScreen extends StatefulWidget {
  const CooperativeProfileScreen({super.key});

  @override
  State<CooperativeProfileScreen> createState() => _CooperativeProfileScreenState();
}

class _CooperativeProfileScreenState extends State<CooperativeProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // Form controllers
  final _cooperativeNameController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _numberOfMembersController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _phoneController = TextEditingController();

  // Location
  String _selectedProvince = '';
  String _selectedDistrict = '';
  String _selectedSector = '';
  String _selectedCell = '';
  String _selectedVillage = '';

  @override
  void dispose() {
    _cooperativeNameController.dispose();
    _registrationNumberController.dispose();
    _numberOfMembersController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
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

      final profile = CooperativeModel(
        id: '',
        userId: userId,
        cooperativeName: _cooperativeNameController.text.trim(),
        registrationNumber: _registrationNumberController.text.trim(),
        numberOfMembers: int.parse(_numberOfMembersController.text),
        location: LocationModel(
          district: _selectedDistrict,
          sector: _selectedSector,
          cell: _selectedCell,
        ),
        contactPerson: _contactPersonController.text.trim(),
        phone: _phoneController.text.trim(),
        availableForSale: false,
      );

      await FirestoreService().createCooperative(profile);

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
    if (_currentPage < 1) {
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
        title: const Text('Farmer Cooperative Profile'),
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
                children: List.generate(2, (index) {
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
                          : (_currentPage == 1 ? _submitProfile : _nextPage),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_currentPage == 1 ? 'Submit' : 'Next'),
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
            'Cooperative Information',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Bean farmers organized in a cooperative',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 24),
          
          TextFormField(
            controller: _cooperativeNameController,
            decoration: const InputDecoration(
              labelText: 'Cooperative Name *',
              hintText: 'e.g., Duterimbere Farmers Cooperative',
              prefixIcon: Icon(Icons.groups),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Cooperative name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _registrationNumberController,
            decoration: const InputDecoration(
              labelText: 'Registration Number *',
              hintText: 'Cooperative registration number',
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
            controller: _numberOfMembersController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Number of Members *',
              hintText: 'e.g., 150',
              prefixIcon: Icon(Icons.people),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Number of members is required';
              }
              if (int.tryParse(value) == null) {
                return 'Enter a valid number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _contactPersonController,
            decoration: const InputDecoration(
              labelText: 'Contact Person *',
              hintText: 'President or Secretary name',
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
          const SizedBox(height: 24),

          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Additional Information',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'After profile approval, you can:\n'
                    '• Record seed purchases from agro-dealers\n'
                    '• Add planting information\n'
                    '• Record harvest data\n'
                    '• List beans for sale to aggregators',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
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
            'Provide your cooperative\'s farming location',
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
              hintText: 'e.g., Bugesera',
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
              hintText: 'e.g., Juru',
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
              labelText: 'Cell *',
              hintText: 'Cell name',
              prefixIcon: Icon(Icons.home_work),
            ),
            onChanged: (value) => _selectedCell = value,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Cell is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Village *',
              hintText: 'Village name',
              prefixIcon: Icon(Icons.home),
            ),
            onChanged: (value) => _selectedVillage = value,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Village is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          Card(
            color: AppTheme.primaryColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.eco, color: AppTheme.primaryColor, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Growing Iron-Biofortified Beans',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'High in iron content, improving nutrition for Rwandans',
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
