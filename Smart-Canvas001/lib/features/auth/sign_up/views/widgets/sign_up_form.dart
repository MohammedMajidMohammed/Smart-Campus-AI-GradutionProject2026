import 'package:smart_canvas/core/cache/cache_helper.dart';
import 'package:smart_canvas/core/components/custom_circular_progress_indecator.dart';
import 'package:smart_canvas/core/components/custom_drop_down_button_form_field.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/components/custom_text_form_field_with_title.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/features/auth/sign_up/view_models/cubit/sign_up_cubit.dart';
import 'package:smart_canvas/features/auth/sign_up/views/widgets/select_college_academic_year.dart';
import 'package:smart_canvas/features/auth/sign_up/views/widgets/select_year_level.dart';

class SignUpForm extends StatelessWidget {
  const SignUpForm({super.key});

  @override
  Widget build(BuildContext context) {
    var cubit = context.read<SignUpCubit>();
    return Form(
      key: cubit.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full Name
          CustomTextFormFieldWithTitle(
            title: "Full Name",
            hintText: "enter your full name",
            prefixIcon: CupertinoIcons.person,
            keyboardType: TextInputType.name,
            controller: cubit.fullNameController,
          ),
          SizedBox(height: SizeConfig.height * 0.01),

          // Email
          CustomTextFormFieldWithTitle(
            title: "Email",
            hintText: "enter your email",
            prefixIcon: CupertinoIcons.mail,
            keyboardType: TextInputType.emailAddress,
            controller: cubit.emailController,
          ),
          SizedBox(height: SizeConfig.height * 0.01),
          // Phone Number
          CustomTextFormFieldWithTitle(
            title: "Phone Number",
            hintText: "enter your phone number",
            prefixIcon: CupertinoIcons.phone,
            keyboardType: TextInputType.phone,
            controller: cubit.phoneController,
          ),
          SizedBox(height: SizeConfig.height * 0.01),

          // Student ID
          if (getIt<CacheHelper>().getData(key: "role_name") == "Student")
            Column(
              children: [
                CustomTextFormFieldWithTitle(
                  title: "Student ID",
                  hintText: "enter your student ID",
                  prefixIcon: CupertinoIcons.info,
                  keyboardType: TextInputType.text,
                  controller: cubit.universityIdController,
                ),
                SizedBox(height: SizeConfig.height * 0.01),
              ],
            ),
          if (getIt<CacheHelper>().getData(key: "role_name") == "Student")
            BlocBuilder<SignUpCubit, SignUpState>(
              buildWhen: (previous, current) =>
                  current is GetCollegesSuccess ||
                  current is GetCollegesLoading ||
                  current is GetCollegesFailure,
              builder: (context, state) {
                if (state is GetCollegesLoading) {
                  return const CustomCircularProgresIndecator();
                }
                if (state is GetCollegesFailure) {
                  return const Text(
                    'Failed to load colleges. Please try again.',
                    style: TextStyle(color: Colors.red),
                  );
                }
                return CustomDropDownButtonFormField(
                  items: cubit.colleges,
                  title: "College",
                  itemLabelBuilder: (e) => e.name,
                  onChanged: (value) {
                    if (value != null) {
                      final college = value;
                      cubit.selectCollege(college: college);
                    }
                  },
                );
              },
            ),
          if (getIt<CacheHelper>().getData(key: "role_name") == "Student")
            Column(
              children: [
                SelectAcademicYear(cubit: cubit),
                SizedBox(height: SizeConfig.height * 0.01),
                SelectYearLevel(cubit: cubit),
                SizedBox(height: SizeConfig.height * 0.01),
              ],
            ),

          // Password
          CustomTextFormFieldWithTitle(
            title: "Password",
            hintText: "enter your password",
            prefixIcon: CupertinoIcons.padlock,
            isPassword: true,
            keyboardType: TextInputType.visiblePassword,
            controller: cubit.passwordController,
          ),
          SizedBox(height: SizeConfig.height * 0.01),
        ],
      ),
    );
  }
}