import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/aggregator_model.dart';
import '../../models/location_model.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../services/firestore_service.dart';

class AggregatorProfileScreen extends StatefulWidget {
  const AggregatorProfileScreen({super.key});

  @override
  State<AggregatorProfileScreen> createState() => _AggregatorProfileScreenState();
}

class _AggregatorProfileScreenState extends State<AggregatorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // Form controllers
  final _businessNameController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _tinNumberController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();

  // Location
  String _selectedProvince = '';
  String _selectedDistrict = '';
  String _selectedSector = '';
  String _selectedCell = '';
  String _selectedVillage = '';

  // Service areas
  final List<String> _serviceAreas = [];
  String? _selectedServiceArea;

  // Storage info
  bool _hasStorage = false;
  final _storageCapacityController = TextEditingController();
  bool _hasRefrigeration = false;
  String _storageType = 'warehouse';

  // Transport info
  bool _hasTransport = false;
  final _numberOfVehiclesController = TextEditingController();
  final _transportCapacityController = TextEditingController();
  bool _hasRefrigeratedTransport = false;

  @override
  void dispose() {
    _businessNameController.dispose();
    _registrationNumberController.dispose();
    _tinNumberController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _storageCapacityController.dispose();
    _numberOfVehiclesController.dispose();
    _transportCapacityController.dispose();
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

      StorageCapacity? storageInfo;
      if (_hasStorage && _storageCapacityController.text.isNotEmpty) {
        storageInfo = StorageCapacity(
          capacityInTons: double.parse(_storageCapacityController.text),
          hasRefrigeration: _hasRefrigeration,
          storageType: _storageType,
        );
      }

      TransportCapacity? transportInfo;
      if (_hasTransport && _numberOfVehiclesController.text.isNotEmpty) {
        transportInfo = TransportCapacity(
          numberOfVehicles: int.parse(_numberOfVehiclesController.text),
          capacityInTons: double.parse(_transportCapacityController.text),
          hasRefrigeratedTransport: _hasRefrigeratedTransport,
        );
      }

      final profile = AggregatorModel(
        id: '',
        userId: userId,
        businessName: _businessNameController.text.trim(),
        registrationNumber: _registrationNumberController.text.trim(),
        tinNumber: _tinNumberController.text.trim(),
        location: LocationModel(
          district: _selectedDistrict,
          sector: _selectedSector,
          cell: _selectedCell,
        ),
        contactPerson: _contactPersonController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        serviceAreas: _serviceAreas,
        storageInfo: storageInfo,
        transportInfo: transportInfo,
        website: _websiteController.text.isNotEmpty 
            ? _websiteController.text.trim() 
            : null,
        createdAt: DateTime.now(),
        isActive: true,
      );

      await FirestoreService().createAggregator(profile);

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
        title: const Text('Aggregator Profile'),
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
                  _buildLocationAndServicePage(),
                  _buildCapacityPage(),
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
            'Business Information',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Traders collecting beans from cooperatives for bulk sales',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 24),
          
          TextFormField(
            controller: _businessNameController,
            decoration: const InputDecoration(
              labelText: 'Business Name *',
              hintText: 'e.g., Rwanda Beans Export Ltd',
              prefixIcon: Icon(Icons.local_shipping),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Business name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _registrationNumberController,
            decoration: const InputDecoration(
              labelText: 'Registration Number *',
              hintText: 'RCA registration number',
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
            controller: _tinNumberController,
            decoration: const InputDecoration(
              labelText: 'TIN Number *',
              hintText: 'Tax Identification Number',
              prefixIcon: Icon(Icons.receipt_long),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'TIN number is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _contactPersonController,
            decoration: const InputDecoration(
              labelText: 'Contact Person *',
              hintText: 'Full name',
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
              hintText: 'business@example.com',
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

  Widget _buildLocationAndServicePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location & Service Areas',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),

          Text(
            'Business Location',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

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
          const SizedBox(height: 32),

          Text(
            'Service Areas',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Districts/Sectors where you collect beans',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedServiceArea,
                  decoration: const InputDecoration(
                    hintText: 'Select district',
                    prefixIcon: Icon(Icons.map),
                  ),
                  items: [
                    'Gasabo', 'Kicukiro', 'Nyarugenge', 'Bugesera',
                    'Gatsibo', 'Kayonza', 'Kirehe', 'Ngoma', 'Rwamagana',
                    'Gicumbi', 'Gakenke', 'Musanze', 'Rulindo', 'Burera',
                  ].map((district) => DropdownMenuItem(
                        value: district,
                        child: Text(district),
                      ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedServiceArea = value);
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  if (_selectedServiceArea != null && 
                      !_serviceAreas.contains(_selectedServiceArea!)) {
                    setState(() {
                      _serviceAreas.add(_selectedServiceArea!);
                      _selectedServiceArea = null;
                    });
                  }
                },
                icon: const Icon(Icons.add_circle),
                color: AppTheme.primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          if (_serviceAreas.isNotEmpty)
            Wrap(
              spacing: 8,
              children: _serviceAreas.map((area) {
                return Chip(
                  label: Text(area),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () {
                    setState(() => _serviceAreas.remove(area));
                  },
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildCapacityPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Storage & Transport Capacity',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),

          // Storage Section
          SwitchListTile(
            title: const Text('Have Storage Facility'),
            value: _hasStorage,
            onChanged: (value) {
              setState(() => _hasStorage = value);
            },
            activeColor: AppTheme.primaryColor,
          ),
          
          if (_hasStorage) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _storageCapacityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Storage Capacity (tons)',
                hintText: 'e.g., 50',
                prefixIcon: Icon(Icons.warehouse),
              ),
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              value: _storageType,
              decoration: const InputDecoration(
                labelText: 'Storage Type',
                prefixIcon: Icon(Icons.category),
              ),
              items: ['warehouse', 'cold storage', 'silo', 'other']
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() => _storageType = value ?? 'warehouse');
              },
            ),
            const SizedBox(height: 16),
            
            SwitchListTile(
              title: const Text('Refrigerated Storage'),
              value: _hasRefrigeration,
              onChanged: (value) {
                setState(() => _hasRefrigeration = value);
              },
              activeColor: AppTheme.primaryColor,
            ),
          ],

          const Divider(height: 32),

          // Transport Section
          SwitchListTile(
            title: const Text('Have Transport Vehicles'),
            value: _hasTransport,
            onChanged: (value) {
              setState(() => _hasTransport = value);
            },
            activeColor: AppTheme.primaryColor,
          ),
          
          if (_hasTransport) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _numberOfVehiclesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Number of Vehicles',
                hintText: 'e.g., 3',
                prefixIcon: Icon(Icons.local_shipping),
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _transportCapacityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Transport Capacity (tons)',
                hintText: 'e.g., 15',
                prefixIcon: Icon(Icons.scale),
              ),
            ),
            const SizedBox(height: 16),
            
            SwitchListTile(
              title: const Text('Refrigerated Transport'),
              value: _hasRefrigeratedTransport,
              onChanged: (value) {
                setState(() => _hasRefrigeratedTransport = value);
              },
              activeColor: AppTheme.primaryColor,
            ),
          ],

          const SizedBox(height: 24),

          Card(
            color: AppTheme.primaryColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'After Profile Approval',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Connect with farmer cooperatives\n'
                    '• Collect iron-biofortified beans\n'
                    '• Sell to institutions in bulk\n'
                    '• Track all transactions',
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
}
