import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_icons/line_icons.dart';
import 'package:smart_canvas/core/components/custom_professional_dialog.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/features/profile/view_models/profile_cubit.dart';
import 'package:smart_canvas/features/profile/view_models/profile_state.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  String? _selectedCollegeId;
  String? _selectedAcademicYearId;
  int? _selectedYearLevel;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();

    // Load initial profile data
    final cubit = context.read<ProfileCubit>();
    if (cubit.state is ProfileLoaded) {
      final data = (cubit.state as ProfileLoaded).userData;
      _nameController.text = data['full_name'] ?? '';
      _phoneController.text = data['phone_number'] ?? '';
      _selectedCollegeId = data['college_id'];
      _selectedAcademicYearId = data['academic_year_id'];
      _selectedYearLevel = data['year_level'];
    } else {
      cubit.loadUserProfile();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final profileCubit = context.read<ProfileCubit>();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
      // Immediately upload the new image
      profileCubit.uploadProfileImage(_imageFile!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0E0A) : const Color(0xFFFAF9F5),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "Edit Profile",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: isDark ? Colors.white : const Color(0xFF1E1B15),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Icon(
              Icons.arrow_back_ios_new, 
              size: 16, 
              color: isDark ? Colors.white : const Color(0xFF1E1B15),
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state is ProfileUpdateSuccess) {
            CustomProfessionalDialog.showSuccess(
              context,
              title: 'Success!',
              message: 'Saved changes successfully',
            );
          } else if (state is ProfileUpdateFailure) {
            CustomProfessionalDialog.showError(
              context,
              title: 'Error',
              message: 'Save failed: ${state.error}',
            );
          } else if (state is ProfileImageUploadSuccess) {
            setState(() {
              _imageFile = null;
            });
            CustomProfessionalDialog.showSuccess(
              context,
              title: 'Success!',
              message: 'Image uploaded successfully',
            );
          } else if (state is ProfileImageUploadFailure) {
            CustomProfessionalDialog.showError(
              context,
              title: 'Error',
              message: 'Upload failed: ${state.error}',
            );
          } else if (state is ProfileLoaded) {
            _nameController.text = state.userData['full_name'] ?? '';
            _phoneController.text = state.userData['phone_number'] ?? '';
            setState(() {
              _selectedCollegeId = state.userData['college_id'];
              _selectedAcademicYearId = state.userData['academic_year_id'];
              _selectedYearLevel = state.userData['year_level'];
            });
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Determine profile image URL
          String? currentImage;
          if (_imageFile != null) {
            currentImage = null; // Displaying local file path instead
          } else if (state is ProfileImageUploadSuccess) {
            currentImage = state.imageUrl;
          } else if (state is ProfileLoaded) {
            currentImage = state.userData['image'];
          }

          return Stack(
            children: [
              // Premium Background Gradient Header
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 320,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isDark
                        ? const LinearGradient(
                            colors: [Color(0xFF1E1B15), Color(0xFF0F0E0A)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          )
                        : LinearGradient(
                            colors: [
                              AppColors.kPrimaryColor.withValues(alpha: 0.15),
                              const Color(0xFFFAF9F5),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                  ),
                ),
              ),

              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        // Premium Profile Avatar with Glowing Ring
                        Center(
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.kPrimaryColor.withValues(alpha: 0.3),
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.kPrimaryColor.withValues(alpha: 0.15),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 65,
                                  backgroundColor: isDark ? Colors.white12 : Colors.grey.shade100,
                                  backgroundImage: _imageFile != null
                                      ? FileImage(_imageFile!) as ImageProvider
                                      : (currentImage != null && currentImage.isNotEmpty
                                          ? CachedNetworkImageProvider(currentImage)
                                          : null),
                                  child: _imageFile == null && (currentImage == null || currentImage.isEmpty)
                                      ? Icon(LineIcons.user, size: 60, color: isDark ? Colors.white30 : Colors.grey.shade400)
                                      : null,
                                ),
                              ),
                              GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF2ECC71), Color(0xFF1E8449)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF0F0E0A) : Colors.white,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF1E8449).withValues(alpha: 0.4),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(LineIcons.camera, size: 20, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 40),

                        // Form Fields enclosed inside a Premium Frosted Glass Card
                        _GlassCard(
                          isDark: isDark,
                          children: [
                            _buildPremiumInputField(
                              context,
                              controller: _nameController,
                              label: "Full Name",
                              icon: LineIcons.user,
                              isDark: isDark,
                              validator: (v) => v!.isEmpty ? "Required" : null,
                            ),
                            const SizedBox(height: 20),
                            _buildPremiumInputField(
                              context,
                              controller: _phoneController,
                              label: "Phone Number",
                              icon: LineIcons.phone,
                              isDark: isDark,
                              keyboardType: TextInputType.phone,
                              validator: (v) => v!.isEmpty ? "Required" : null,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 40),

                        // Animated Glowing Save Button
                        _InteractiveSaveButton(
                          onTap: () {
                            if (_formKey.currentState!.validate()) {
                              context.read<ProfileCubit>().updateProfile(
                                name: _nameController.text.trim(),
                                phone: _phoneController.text.trim(),
                                collegeId: _selectedCollegeId,
                                academicYearId: _selectedAcademicYearId,
                                yearLevel: _selectedYearLevel,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPremiumInputField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return _GlowTextField(
      controller: controller,
      label: label,
      icon: icon,
      isDark: isDark,
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}

// Stateful textfield to support active focus neon glows and icon transitions
class _GlowTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isDark;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _GlowTextField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.isDark,
    this.keyboardType,
    this.validator,
  });

  @override
  State<_GlowTextField> createState() => _GlowTextFieldState();
}

class _GlowTextFieldState extends State<_GlowTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF2ECC71);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _isFocused 
                ? activeColor 
                : (widget.isDark ? Colors.white38 : Colors.grey.shade600),
            letterSpacing: 0.5,
          ),
          child: Text(widget.label),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          keyboardType: widget.keyboardType,
          style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87),
          validator: widget.validator,
          decoration: InputDecoration(
            prefixIcon: AnimatedTheme(
              data: ThemeData(iconTheme: const IconThemeData(color: activeColor)),
              child: Icon(widget.icon, color: _isFocused ? activeColor : (widget.isDark ? Colors.white38 : Colors.grey.shade400)),
            ),
            filled: true,
            fillColor: widget.isDark 
                ? Colors.black.withValues(alpha: 0.2) 
                : Colors.grey.shade50.withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: widget.isDark ? Colors.white12 : Colors.grey.shade200,
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: activeColor, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ],
    );
  }
}

// Glassmorphic Card Container
class _GlassCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;

  const _GlassCard({
    required this.isDark,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

// Custom Glassmorphic Animated Save Changes Button
class _InteractiveSaveButton extends StatefulWidget {
  final VoidCallback onTap;
  const _InteractiveSaveButton({required this.onTap});

  @override
  State<_InteractiveSaveButton> createState() => _InteractiveSaveButtonState();
}

class _InteractiveSaveButtonState extends State<_InteractiveSaveButton> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const greenColor = Color(0xFF2ECC71);
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _scaleController.forward(),
        onTapUp: (_) {
          _scaleController.reverse();
          widget.onTap();
        },
        onTapCancel: () => _scaleController.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2ECC71), Color(0xFF1E8449)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: greenColor.withValues(alpha: _isHovered ? 0.35 : 0.2),
                  blurRadius: _isHovered ? 18 : 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                "Save Changes",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
