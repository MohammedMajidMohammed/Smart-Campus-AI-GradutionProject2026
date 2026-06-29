import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'administrator_bottom_nav_bar_state.dart';

class AdministratorBottomNavBarCubit extends Cubit<int> {
  AdministratorBottomNavBarCubit() : super(0);
  // change index
  void changeIndex(int index) => emit(index);
}
