import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'student_bottom_nav_bar_state.dart';

class StudentBottomNavBarCubit extends Cubit<int> {
  StudentBottomNavBarCubit() : super(0);
  // change index
  void changeIndex(int index) => emit(index);
}
