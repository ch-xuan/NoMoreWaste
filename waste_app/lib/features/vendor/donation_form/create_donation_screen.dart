import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/models/donation.dart';
import '../../../data/repositories/donation_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../core/services/image_service.dart';
import '../../../core/widgets/nmw_button.dart';
import '../../../core/widgets/nmw_text_field.dart';
import 'description_generator.dart';

class CreateDonationScreen extends StatefulWidget {
  const CreateDonationScreen({super.key});

  @override
  State<CreateDonationScreen> createState() => _CreateDonationScreenState();
}

class _CreateDonationScreenState extends State<CreateDonationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _donationRepo = DonationRepository();
  final _userRepo = UserRepository();
  final _imageService = ImageService();
  final _descriptionGen = DescriptionGenerator();
  bool _isGeneratingDesc = false;

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _addressController = TextEditingController();

  // Selections
  String? _selectedCategory; // null until user selects a category 
  String _selectedUnit = 'Kilograms (kg)';
  DateTime? _expiryDate;
  TimeOfDay? _expiryTime;
  TimeOfDay? _pickupStart;
  TimeOfDay? _pickupEnd;
  bool _containsAllergens = false;
  List<String> _foodPhotos = []; // Support up to 2 photos

  bool _isLoading = false;
  bool _isProcessingImage = false;
  bool _isVerified = true;

  final List<String> _categories = [
    'Cooked Food',
    'Drinks',
    'Packaged Food',
    'Baked Goods',
    'Fresh Produce',
  ];

  final List<String> _units = [
    'Kilograms (kg)',
    'Units',
    'Servings',
  ];

  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
  }

  Future<void> _checkVerificationStatus() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final userProfile = await _userRepo.getUserProfile(userId);
    if (userProfile != null) {
      setState(() {
        _isVerified = userProfile['verificationStatus'] == 'approved';
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _addPhoto({required bool fromCamera}) async {
    if (_foodPhotos.length >= 2) {
      _showError('Maximum 2 photos allowed');
      return;
    }

    setState(() => _isProcessingImage = true);
    try {
      final base64 = fromCamera
          ? await _imageService.pickFromCameraAndConvert()
          : await _imageService.pickFromGalleryAndConvert();
      if (base64 != null) {
        setState(() => _foodPhotos.add(base64));
      }
    } catch (e) {
      _showError('Failed to add image: $e');
    } finally {
      setState(() => _isProcessingImage = false);
    }
  }

  void _removePhoto(int index) {
    setState(() => _foodPhotos.removeAt(index));
  }

  Future<void> _selectTime(BuildContext context, String type) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null && mounted) {
      setState(() {
        if (type == 'expiryTime') {
          _expiryTime = time;
        } else if (type == 'pickupStart') {
          _pickupStart = time;
        } else if (type == 'pickupEnd') {
          _pickupEnd = time;
        }
      });
    }
  }

  Future<void> _selectDate(BuildContext context, String type) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );

    if (date != null && mounted) {
      setState(() {
        _expiryDate = date;
      });
    }
  }

  Future<void> _submitDonation() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedCategory == null || !_categories.contains(_selectedCategory)) {
      _showError('Please select a valid food category');
      return;
    }
    
    if (_expiryDate == null || _expiryTime == null) {
      _showError('Please select expiry date and time');
      return;
    }

    if (_pickupStart == null || _pickupEnd == null) {
      _showError('Please select pickup start and end times');
      return;
    }

    if (!_isVerified) {
      _showError('Your account is pending verification. Please wait for admin approval.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final userProfile = await _userRepo.getUserProfile(user.uid);
      if (userProfile == null) throw Exception('User profile not found');

      final expiryDateTime = DateTime(
        _expiryDate!.year,
        _expiryDate!.month,
        _expiryDate!.day,
        _expiryTime!.hour,
        _expiryTime!.minute,
      );

      // Combine pickup start/end with expiry date for full DateTime
      final pickupStartDateTime = DateTime(
        _expiryDate!.year,
        _expiryDate!.month,
        _expiryDate!.day,
        _pickupStart!.hour,
        _pickupStart!.minute,
      );

      final pickupEndDateTime = DateTime(
        _expiryDate!.year,
        _expiryDate!.month,
        _expiryDate!.day,
        _pickupEnd!.hour,
        _pickupEnd!.minute,
      );

      final donation = Donation(
        id: '',
        vendorId: user.uid,
        vendorName: userProfile['orgName'] ?? userProfile['displayName'] ?? 'Unknown Vendor',
        foodType: _mapCategoryToFoodType(_selectedCategory!),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        quantity: _quantityController.text.trim(),
        unit: _selectedUnit,
        expiryTime: expiryDateTime,
        pickupWindowStart: pickupStartDateTime,
        pickupWindowEnd: pickupEndDateTime,
        pickupAddress: _addressController.text.trim(),
        containsAllergens: _containsAllergens,
        photos: _foodPhotos.isNotEmpty ? _foodPhotos : null,
        location: null,
        status: DonationStatus.available,
        createdAt: DateTime.now(),
      );

      await _donationRepo.createDonation(donation);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Donation created successfully!')),
        );
      }
    } catch (e) {
      _showError('Failed to create donation: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  FoodType _mapCategoryToFoodType(String category) {
    switch (category) {
      case 'Baked Goods':
        return FoodType.bakedGoods;
      case 'Fresh Produce':
        return FoodType.freshProduce;
      case 'Cooked Food':
        return FoodType.cookedFood;
      case 'Drinks':
        return FoodType.drinks;
      case 'Packaged Food':
        return FoodType.packagedFood;
      default:
        return FoodType.other;
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _generateDescription() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showError('Please enter a food title first.');
      return;
    }

    setState(() => _isGeneratingDesc = true);

    // Small delay to simulate "thinking" for UX feel
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;

      final variants = _descriptionGen.generateVariants(
        title: title,
        category: _selectedCategory,
        quantity: _quantityController.text.trim(),
        unit: _selectedUnit,
        containsAllergens: _containsAllergens,
      );

      setState(() => _isGeneratingDesc = false);

      final labels = ['Professional', 'Warm & Friendly', 'Brief'];
      final icons = [Icons.business, Icons.favorite, Icons.flash_on];
      final colors = [
        const Color(0xFF1B7F5A),
        const Color(0xFFD946EF),
        const Color(0xFFD0893E),
      ];

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.65,
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Descriptions',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Pick a style that suits your donation',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: variants.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    return InkWell(
                      onTap: () {
                        _descriptionController.text = variants[i];
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${labels[i]} description applied!'),
                            backgroundColor: colors[i],
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: colors[i].withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(14),
                          color: colors[i].withOpacity(0.04),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(icons[i], size: 18, color: colors[i]),
                                const SizedBox(width: 8),
                                Text(
                                  labels[i],
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: colors[i],
                                  ),
                                ),
                                const Spacer(),
                                Icon(Icons.arrow_forward_ios, size: 14, color: colors[i].withOpacity(0.5)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              variants[i],
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildPhotoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Food Photo',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          
          // Display existing photos
          if (_foodPhotos.isNotEmpty)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _foodPhotos.asMap().entries.map((entry) {
                final index = entry.key;
                final photo = entry.value;
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        base64Decode(photo),
                        height: 120,
                        width: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removePhoto(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          
          if (_foodPhotos.isNotEmpty) const SizedBox(height: 12),
          
          // Add photo buttons (show only if less than 2 photos)
          if (_foodPhotos.length < 2)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessingImage ? null : () => _addPhoto(fromCamera: true),
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('Take Photo'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessingImage ? null : () => _addPhoto(fromCamera: false),
                    icon: const Icon(Icons.upload, size: 18),
                    label: const Text('Upload'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ],
            ),
          
          if (_foodPhotos.length < 2)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${_foodPhotos.length}/2 photos added',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Post Donation', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: false,
        backgroundColor: const Color(0xFF22A45D),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Section
              _buildPhotoSection(),
              const SizedBox(height: 16),

              // Food Details Container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NmwTextField(
                      controller: _titleController,
                      hint: 'e.g., Fresh Vegetable Curry',
                      label: 'Food Title *',
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    // Description field with Generate button
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Description',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: _isGeneratingDesc ? null : _generateDescription,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                      color: const Color(0xFF8B5CF6).withOpacity(0.3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _isGeneratingDesc
                                        ? const SizedBox(
                                            width: 14, height: 14,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Generate',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        NmwTextField(
                          controller: _descriptionController,
                          hint: 'Tap \"Generate\" or type your own description...',
                          maxLines: 3,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Category Dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Category *',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          hint: const Text('Please select a category'),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                          onChanged: (val) => setState(() => _selectedCategory = val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: NmwTextField(
                            controller: _quantityController,
                            hint: '0',
                            label: 'Quantity *',
                            keyboardType: TextInputType.number,
                            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Unit',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _selectedUnit,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                ),
                                items: _units.map((unit) => DropdownMenuItem(value: unit, child: Text(unit))).toList(),
                                onChanged: (val) => setState(() => _selectedUnit = val!),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Expiry & Pickup Container - 2x2 Grid
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Expiry & Pickup Details',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    
                    // Row 1: Expiry Date & Expiry Time
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Expiry Date *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => _selectDate(context, 'expiry'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 18, color: Colors.grey.shade600),
                                      const SizedBox(width: 8),
                                      Text(
                                        _expiryDate == null ? 'mm/dd/yyyy' : '${_expiryDate!.month}/${_expiryDate!.day}/${_expiryDate!.year}',
                                        style: TextStyle(color: _expiryDate == null ? Colors.grey.shade500 : Colors.black87),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Expiry Time *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => _selectTime(context, 'expiryTime'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.access_time, size: 18, color: Colors.grey.shade600),
                                      const SizedBox(width: 8),
                                      Text(
                                        _expiryTime == null ? '--:-- --' : _expiryTime!.format(context),
                                        style: TextStyle(color: _expiryTime == null ? Colors.grey.shade500 : Colors.black87),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Row 2: Pickup Start & Pickup End
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Pickup Start *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => _selectTime(context, 'pickupStart'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.access_time, size: 18, color: Colors.grey.shade600),
                                      const SizedBox(width: 8),
                                      Text(
                                        _pickupStart == null ? '--:-- --' : _pickupStart!.format(context),
                                        style: TextStyle(color: _pickupStart == null ? Colors.grey.shade500 : Colors.black87),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Pickup End *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => _selectTime(context, 'pickupEnd'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.access_time, size: 18, color: Colors.grey.shade600),
                                      const SizedBox(width: 8),
                                      Text(
                                        _pickupEnd == null ? '--:-- --' : _pickupEnd!.format(context),
                                        style: TextStyle(color: _pickupEnd == null ? Colors.grey.shade500 : Colors.black87),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Location Dropdown (Specific Areas)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pickup Location *',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _addressController.text.isNotEmpty ? _addressController.text : null,
                          hint: const Text('Select pickup area'),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            prefixIcon: Icon(Icons.location_on, color: Colors.grey.shade600, size: 20),
                          ),
                          items: [
                            'Kuchai Lama',
                            'Puchong',
                            'OUG',
                            'Bukit Jalil',
                          ].map((location) => DropdownMenuItem(value: location, child: Text(location))).toList(),
                          onChanged: (val) => setState(() => _addressController.text = val!),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Allergens Container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Contains Allergens', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          SizedBox(height: 2),
                          Text(
                            'Check if food contains common allergens (nuts, dairy, gluten, etc.)',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _containsAllergens,
                      onChanged: (val) => setState(() => _containsAllergens = val),
                      activeColor: Colors.orange,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              NmwButton(
                text: _isLoading ? 'Creating...' : 'Post Donation',
                onPressed: _isLoading ? null : _submitDonation,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
