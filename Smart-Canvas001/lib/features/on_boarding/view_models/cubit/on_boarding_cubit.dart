import 'package:bloc/bloc.dart';
import 'package:smart_canvas/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
part 'on_boarding_state.dart';

class OnBoardingCubit extends Cubit<int> {
  OnBoardingCubit() : super(0);
  final PageController pageController = PageController();
  int currentIndex = 0;
  // next page
  void nextPage() {
    if (currentIndex < AppConstants.onBoardingList.length - 1) {
      currentIndex++;
      pageController.animateToPage(
        currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
      emit(currentIndex);
    } else {
      emit(++currentIndex);
    }
  }

  // on page changed
  void onPageChanged(int index) {
    currentIndex = index;
    emit(index);
  }
}
