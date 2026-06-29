import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'doctor_bottom_nav_bar_state.dart';

class DoctorBottomNavBarCubit extends Cubit<int> {
  DoctorBottomNavBarCubit() : super(0);
  // change index
  void changeIndex(int index) => emit(index);
}
