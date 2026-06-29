import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smart_canvas/core/app_route/route_names.dart';
import 'package:smart_canvas/core/cache/cache_helper.dart';
import 'package:smart_canvas/core/components/custom_elevated_button.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/core/utilies/assets/images/app_images.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/extensions/app_extensions.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/core/utilies/styles/app_text_styles.dart';
import 'package:smart_canvas/features/administrator/buildings/views/widgets/custom_loading_indecator.dart';
import 'package:smart_canvas/features/splash/views/widgets/gradient_body.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // أضف supabase_flutter في pubspec.yaml: supabase_flutter: ^2.5.6

// Role model (نفس اللي قبل كده)
class RoleModel {
  final String id;
  final String name;
  final String? imageUrl;

  RoleModel({required this.id, required this.name, this.imageUrl});

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['image'],
    );
  }
}

// دالة ديناميكية لجلب الـ roles من Supabase
Future<List<RoleModel>> fetchRoles() async {
  try {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('roles')
        .select('id, name, image')
        .order('created_at', ascending: false); // جلب حسب التاريخ التنازلي

    if (response.isEmpty) {
      throw Exception('No roles found');
    }

    return response.map((json) => RoleModel.fromJson(json)).toList();
  } catch (e) {
    // في حالة خطأ (شبكة، إذن، إلخ)
    throw Exception('Error fetching roles: $e');
  }
}

class SelectRoleScreen extends StatefulWidget {
  const SelectRoleScreen({super.key});

  @override
  State<SelectRoleScreen> createState() => _SelectRoleScreenState();
}

class _SelectRoleScreenState extends State<SelectRoleScreen>
    with TickerProviderStateMixin {
  String? selectedRoleId;
  late Future<List<RoleModel>> _rolesFuture;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _rolesFuture = fetchRoles().catchError((error) {
      debugPrint('Fetch error: $error');
      return <RoleModel>[]; // fallback لقائمة فارغة
    });
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          ),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = SizeConfig.width;
    final height = SizeConfig.height;

    return GradientBody(
      child: SafeArea(
        bottom: false,
        child: FutureBuilder<List<RoleModel>>(
          future: _rolesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState(width, height);
            }
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return _buildErrorState(width, height, snapshot.error.toString());
            }

            final roles = snapshot.data!;
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                // إضافة ScrollView للشاشة بأكملها لضمان ظهور كل العناصر
                padding: EdgeInsets.only(
                  top: height * 0.02,
                  left: width * 0.05,
                  right: width * 0.05,
                ),
                child: ConstrainedBox(
                  // لتحديد المساحة المتاحة
                  constraints: BoxConstraints(
                    minHeight:
                        height *
                        0.95, // يضمن أن الشاشة تملأ تقريباً كامل الارتفاع
                  ),
                  child: IntrinsicHeight(
                    // يجعل العمود يأخذ الارتفاع الطبيعي
                    child: Column(
                      children: [
                        SizedBox(
                          height: height * 0.02,
                        ), // تقليل المسافة العلوية قليلاً للتوازن
                        SlideTransition(
                          position: _slideAnimation,
                          child: Image.asset(
                            AppImages.logoImage,
                            width:
                                width * 0.4, // تقليل حجم اللوجو قليلاً للتوازن
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(
                          height: height * 0.015,
                        ), // تقليل المسافة بين اللوجو والعنوان
                        /// Title (مع تحسين الـ styling ليكون أكبر وأجذب)
                        Text(
                          'Select your role',
                          style: AppTextStyles.title20kPrimaryColorBold
                              .copyWith(
                                fontSize:
                                    width * 0.07, // تعديل حجم الخط للتوازن
                                color: AppColors.kPrimaryColor,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(
                          height: height * 0.03, // تقليل المسافة قليلاً للضيق
                        ),

                        /// Dynamic Roles list from Supabase - تحسين: استخدام GridView لعرض مربع (2 في الصف)
                        GridView.builder(
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(), // منع التمرير الداخلي
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, // 2 كروت في الصف للشكل المربع
                            childAspectRatio:
                                0.85, // زيادة النسبة قليلاً لجعل الكروت أعرض وأقل ارتفاعاً لتجنب الضغط
                            crossAxisSpacing:
                                width *
                                0.04, // زيادة المسافة الأفقية قليلاً للتوازن
                            mainAxisSpacing:
                                height * 0.02, // تقليل المسافة الرأسية قليلاً
                          ),
                          itemCount: roles.length,
                          itemBuilder: (context, index) {
                            final role = roles[index];
                            return RoleCard(
                              role: role,
                              isSelected: selectedRoleId == role.id,
                              onTap: () =>
                                  setState(() => selectedRoleId = role.id),
                            );
                          },
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.3),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              ),
                          child: selectedRoleId != null
                              ? SizedBox(
                                  width: double.infinity,
                                  child: CustomElevatedButton(
                                    name: "Continue",
                                    onPressed: () async {
                                      final cache = getIt<CacheHelper>();
                                      await cache.saveData(
                                        key: "role_id",
                                        value: selectedRoleId!,
                                      );
                                      // Save name for quick use
                                      final selectedRole = roles.firstWhere(
                                        (r) => r.id == selectedRoleId,
                                      );
                                      await cache.saveData(
                                        key: "role_name",
                                        value: selectedRole.name,
                                      );
                                      if (context.mounted) {
                                        context.pushReplacementScreen(
                                          RouteNames.signUpScreen,
                                        );
                                      }
                                    },
                                    hPadding: height * 0.02,
                                  ),
                                )
                              : SizedBox(
                                  key: const ValueKey("no_selection"),
                                  height: height * 0.05,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState(double width, double height) {
    return const CustomLoadingIndecator();
  }

  Widget _buildErrorState(double width, double height, String? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: width * 0.15, color: Colors.grey),
          SizedBox(height: height * 0.02),
          Text(
            error ?? 'Error loading roles',
            style: AppTextStyles.title16Black,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: height * 0.02),
          ElevatedButton(
            onPressed: () => setState(() => _rolesFuture = fetchRoles()),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// RoleCard (تحسين: استخدام Stack لترتيب العناصر بشكل صحيح، مع وضع الـ check icon في Positioned لتجنب الـ overflow، وتعديل المساحات داخل الكارد)
class RoleCard extends StatelessWidget {
  const RoleCard({
    super.key,
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  final RoleModel role;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = SizeConfig.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        clipBehavior: Clip.none,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.kPrimaryColor.withValues(alpha: 0.15) : AppColors.kPrimaryColor.withValues(alpha: 0.05))
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.7)),
          borderRadius: BorderRadius.circular(width * 0.08),
          border: Border.all(
            color: isSelected ? AppColors.kPrimaryColor : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200),
            width: width * 0.006,
          ),
          boxShadow: [
            BoxShadow(
              color: (isSelected ? AppColors.kPrimaryColor : (isDark ? Colors.black : Colors.grey))
                  .withValues(alpha: isDark ? 0.3 : 0.1),
              blurRadius: width * 0.08,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          // استخدام Stack لترتيب العناصر دون overflow
          children: [
            // الـ Column الرئيسي للصورة والنص
            Column(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween, // توزيع المساحة بشكل أفضل
              children: [
                // الصورة كبيرة في الأعلى (مع ارتفاع محدد لتجنب الضغط)
                Expanded(
                  flex: 6, // تخصيص نسبة أكبر للصورة
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(width * 0.08),
                      topRight: Radius.circular(width * 0.08),
                    ),
                    child: role.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: role.imageUrl!,
                            alignment: Alignment.center,
                            width: double.infinity,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey.shade300,
                              child: const Icon(
                                Icons.error_outline,
                                color: Colors.grey,
                                size: 40,
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: Image.asset(
                              AppImages.profileImage,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                ),
                // النص في الأسفل مع مساحة كافية
                Expanded(
                  flex: 4, // تخصيص نسبة للنص
                  child: Padding(
                    padding: EdgeInsets.all(
                      width * 0.02,
                    ), // إضافة padding داخلي للنص
                    child: Text(
                      role.name,
                      style: AppTextStyles.title20kPrimaryColorBold.copyWith(
                        color: isSelected
                            ? AppColors.kPrimaryColor
                            : (isDark ? Colors.white70 : Colors.black87),
                        fontSize:
                            width * 0.045, // تقليل حجم النص قليلاً لتجنب الضغط
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w600,
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            // الـ check icon في الزاوية العلوية اليمنى (Positioned داخل Stack)
            if (isSelected)
              Positioned(
                bottom: SizeConfig.height * 0.005,
                right: width * 0.05,
                left: width * 0.05,
                child: Container(
                  padding: const EdgeInsets.all(
                    5,
                  ), // تقليل padding قليلاً للتوازن
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.kPrimaryColor,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: AppColors.kPrimaryColor,
                    size:
                        width *
                        0.06, // تقليل حجم الأيقونة قليلاً لتجنب الخروج عن الحدود
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
