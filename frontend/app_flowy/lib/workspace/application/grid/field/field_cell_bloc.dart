import 'package:app_flowy/workspace/application/grid/field/field_listener.dart';
import 'package:app_flowy/workspace/application/grid/field/field_service.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart' show Field;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

part 'field_cell_bloc.freezed.dart';

class FieldCellBloc extends Bloc<FieldCellEvent, FieldCellState> {
  final FieldListener _fieldListener;

  FieldCellBloc({
    required GridFieldCellContext cellContext,
  })  : _fieldListener = FieldListener(fieldId: cellContext.field.id),
        super(FieldCellState.initial(cellContext)) {
    on<FieldCellEvent>(
      (event, emit) async {
        await event.map(
          initial: (_InitialCell value) async {
            _startListening();
          },
          didReceiveFieldUpdate: (_DidReceiveFieldUpdate value) {
            emit(state.copyWith(field: value.field));
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    await _fieldListener.stop();
    return super.close();
  }

  void _startListening() {
    _fieldListener.updateFieldNotifier.addPublishListener((result) {
      result.fold(
        (field) => add(FieldCellEvent.didReceiveFieldUpdate(field)),
        (err) => Log.error(err),
      );
    });
    _fieldListener.start();
  }
}

@freezed
class FieldCellEvent with _$FieldCellEvent {
  const factory FieldCellEvent.initial() = _InitialCell;
  const factory FieldCellEvent.didReceiveFieldUpdate(Field field) = _DidReceiveFieldUpdate;
}

@freezed
class FieldCellState with _$FieldCellState {
  const factory FieldCellState({
    required String gridId,
    required Field field,
  }) = _FieldCellState;

  factory FieldCellState.initial(GridFieldCellContext cellContext) => FieldCellState(
        gridId: cellContext.gridId,
        field: cellContext.field,
      );
}
