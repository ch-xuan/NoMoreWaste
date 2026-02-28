import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/repositories/donation_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/models/donation.dart';
import '../../../core/services/image_service.dart';
import '../../../core/widgets/nmw_text_field.dart';

/// Screen for editing an existing donation
class EditDonationScreen extends StatefulWidget {
  const EditDonationScreen({super.key, required this.donation});

  final Donation donation;

  @override
  State<EditDonationScreen> createState() => _EditDonationScreenState();
}

class _EditDonationScreenState extends State<EditDonationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _donationRepo = DonationRepository();
  final _userRepo = UserRepository();
  final _imageService = ImageService();

  // Controllers - initialized with existing values
  late final _titleController = TextEditingController(text: widget.donation.title);
  late final _descriptionController = TextEditingController(text: widget.donation.description ?? '');
  late final _quantityController = TextEditingController(text: widget.donation.quantity);
  late final _addressController = TextEditingController(text: widget.donation.pickupAddress);

  // Selections - initialized with existing values
  String? _selectedCategory;
  late String _selectedUnit = widget.donation.unit ?? 'Kilograms (kg)';
  DateTime? _expiryDate;
  TimeOfDay? _expiryTime;
  TimeOfDay? _pickupStart;
  TimeOfDay? _pickupEnd;
  late bool _containsAllergens = widget.donation.containsAllergens;
  List<String> _foodPhotos = [];

  bool _isLoading = false;
  bool _isProcessingImage = false;

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

  final List<String> _pickupLocations = [
    'Kuchai Lama',
    'Puchong',
    'OUG',
    'Bukit Jalil',
  ];

  @override
  void initState() {
    super.initState();
    _initializeFromDonation();
  }

  void _initializeFromDonation() {
    // Initialize category from foodType
    _selectedCategory = _foodTypeToCategory(widget.donation.foodType);
    
    // Initialize date/time from donation
    _expiryDate = DateTime(
      widget.donation.expiryTime.year,
      widget.donation.expiryTime.month,
      widget.donation.expiryTime.day,
    );
    _expiryTime = TimeOfDay.fromDateTime(widget.donation.expiryTime);
    
    if (widget.donation.pickupWindowStart != null) {
      _pickupStart = TimeOfDay.fromDateTime(widget.donation.pickupWindowStart!);
    }
    if (widget.donation.pickupWindowEnd != null) {
      _pickupEnd = TimeOfDay.fromDateTime(widget.donation.pickupWindowEnd!);
    }
    
    // Initialize photos
    if (widget.donation.photos != null) {
      _foodPhotos = List.from(widget.donation.photos!);
    }
  }

  String _foodTypeToCategory(FoodType foodType) {
    switch (foodType) {
      case FoodType.bakedGoods:
        return 'Baked Goods';
      case FoodType.freshProduce:
        return 'Fresh Produce';
      case FoodType.cookedFood:
        return 'Cooked Food';
      case FoodType.drinks:
        return 'Drinks';
      case FoodType.packagedFood:
        return 'Packaged Food';
      default:
        return 'Cooked Food';
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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _updateDonation() async {
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

    setState(() => _isLoading = true);

    try {
      final expiryDateTime = DateTime(
        _expiryDate!.year,
        _expiryDate!.month,
        _expiryDate!.day,
        _expiryTime!.hour,
        _expiryTime!.minute,
      );

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

      final updatedDonation = widget.donation.copyWith(
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
      );

      await _donationRepo.updateDonation(updatedDonation.id, updatedDonation.toJson());

      if (mounted) {
        Navigator.pop(context, updatedDonation); // Return the updated donation object
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Donation updated successfully!')),
        );
      }
    } catch (e) {
      _showError('Failed to update donation: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _addPhoto(ImageSource source) async {
    if (_foodPhotos.length >= 2) {
      _showError('Maximum 2 photos allowed');
      return;
    }

    setState(() => _isProcessingImage = true);
    
    try {
      final String? base64Image;
      if (source == ImageSource.camera) {
        base64Image = await _imageService.pickFromCameraAndConvert();
      } else {
        base64Image = await _imageService.pickFromGalleryAndConvert();
      }

      if (base64Image != null && base64Image.isNotEmpty) {
        setState(() => _foodPhotos.add(base64Image!));
      }
    } catch (e) {
      _showError('Failed to process image: $e');
    } finally {
      setState(() => _isProcessingImage = false);
    }
  }

  void _removePhoto(int index) {
    setState(() => _foodPhotos.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EA),
      appBar: AppBar(
        title: const Text('Edit Donation'),
        backgroundColor: const Color(0xFF22A45D),
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _updateDonation,
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photos Section (similar to create screen)
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
                      'Food Photos (Max 2)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    if (_foodPhotos.isNotEmpty)
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _foodPhotos.asMap().entries.map((entry) {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  base64Decode(entry.value),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removePhoto(entry.key),
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (_foodPhotos.length < 2) ...[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isProcessingImage ? null : () => _addPhoto(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Take Photo'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isProcessingImage ? null : () => _addPhoto(ImageSource.gallery),
                              icon: const Icon(Icons.upload),
                              label: const Text('Upload'),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (_isProcessingImage)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: LinearProgressIndicator(),
                      ),
                    Text(
                      '${_foodPhotos.length}/2 photos added',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Basic Details (Title, Description, Category, Quantity, Unit)
              // ... rest of the form similar to create screen but with pre-filled values
              // Title
              NmwTextField(
                controller: _titleController,
                label: 'Listing Title',
                hint: 'e.g. 50kg of Surplus Bread',
                validator: (val) => val == null || val.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),

              // Description
              NmwTextField(
                controller: _descriptionController,
                label: 'Description (Optional)',
                hint: 'Describe the food items...',
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Category',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black.withOpacity(0.08)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        hint: const Text('Please select a category'),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedCategory = val),
                        validator: (val) => val == null ? 'Please select a category' : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Quantity & Unit
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: NmwTextField(
                      controller: _quantityController,
                      label: 'Quantity',
                      hint: 'e.g. 10',
                      keyboardType: TextInputType.number,
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Unit',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 54, // Match text field height roughly
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black.withOpacity(0.08)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedUnit,
                              isExpanded: true,
                              items: _units.map((unit) {
                                return DropdownMenuItem(
                                  value: unit,
                                  child: Text(unit, maxLines: 1, overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedUnit = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Dates Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dates & Times', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildDatePicker()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTimePicker('Expiry Time', _expiryTime, (t) => setState(() => _expiryTime = t))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTimePicker('Pickup Start', _pickupStart, (t) => setState(() => _pickupStart = t))),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTimePicker('Pickup End', _pickupEnd, (t) => setState(() => _pickupEnd = t))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Pickup Address
              // Pickup Location Dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pickup Location',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black.withOpacity(0.08)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<String>(
                        value: _pickupLocations.contains(_addressController.text) 
                            ? _addressController.text 
                            : null,
                        hint: const Text('Select pickup area'),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          icon: Icon(Icons.location_on, size: 20, color: Colors.grey),
                        ),
                        items: _pickupLocations.map((location) {
                          return DropdownMenuItem(
                            value: location,
                            child: Text(location),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _addressController.text = val!),
                        validator: (val) => val == null ? 'Location is required' : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Allergens
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black.withOpacity(0.08)),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Contains Allergens?',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Nuts, dairy, soy, seafood, etc.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  value: _containsAllergens,
                  activeColor: const Color(0xFF22A45D),
                  onChanged: (val) => setState(() => _containsAllergens = val),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Expiry Date', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: _expiryDate ?? now,
              firstDate: now,
              lastDate: now.add(const Duration(days: 30)),
            );
            if (picked != null) {
              setState(() => _expiryDate = picked);
            }
          },
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  _expiryDate != null
                      ? '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'
                      : 'Select Date',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay? time, Function(TimeOfDay) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: time ?? TimeOfDay.now(),
            );
            if (picked != null) {
              onChanged(picked);
            }
          },
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  time != null ? time.format(context) : 'Select Time',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}