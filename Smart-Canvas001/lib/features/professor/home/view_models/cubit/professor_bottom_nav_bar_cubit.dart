import 'package:flutter_bloc/flutter_bloc.dart';

class ProfessorBottomNavBarCubit extends Cubit<int> {
  ProfessorBottomNavBarCubit() : super(0);

  void changeIndex(int index) => emit(index);
}
