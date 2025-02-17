import 'package:app_flowy/workspace/application/grid/cell_bloc/cell_listener.dart';
import 'package:app_flowy/workspace/application/grid/row/row_service.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart' show Cell;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'cell_service.dart';

part 'checkbox_cell_bloc.freezed.dart';

class CheckboxCellBloc extends Bloc<CheckboxCellEvent, CheckboxCellState> {
  final CellService _service;
  final CellListener _listener;

  CheckboxCellBloc({
    required CellService service,
    required CellData cellData,
  })  : _service = service,
        _listener = CellListener(rowId: cellData.rowId, fieldId: cellData.field.id),
        super(CheckboxCellState.initial(cellData)) {
    on<CheckboxCellEvent>(
      (event, emit) async {
        await event.map(
          initial: (_Initial value) {
            _startListening();
          },
          select: (_Selected value) async {
            _updateCellData();
          },
          didReceiveCellUpdate: (_DidReceiveCellUpdate value) {
            emit(state.copyWith(isSelected: _isSelected(value.cell)));
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    await _listener.stop();
    return super.close();
  }

  void _startListening() {
    _listener.updateCellNotifier.addPublishListener((result) {
      result.fold(
        (notificationData) async => await _loadCellData(),
        (err) => Log.error(err),
      );
    });
    _listener.start();
  }

  Future<void> _loadCellData() async {
    final result = await _service.getCell(
      gridId: state.cellData.gridId,
      fieldId: state.cellData.field.id,
      rowId: state.cellData.rowId,
    );
    result.fold(
      (cell) {
        if (!isClosed) {
          add(CheckboxCellEvent.didReceiveCellUpdate(cell));
        }
      },
      (err) => Log.error(err),
    );
  }

  void _updateCellData() {
    _service.updateCell(
      gridId: state.cellData.gridId,
      fieldId: state.cellData.field.id,
      rowId: state.cellData.rowId,
      data: !state.isSelected ? "Yes" : "No",
    );
  }
}

@freezed
class CheckboxCellEvent with _$CheckboxCellEvent {
  const factory CheckboxCellEvent.initial() = _Initial;
  const factory CheckboxCellEvent.select() = _Selected;
  const factory CheckboxCellEvent.didReceiveCellUpdate(Cell cell) = _DidReceiveCellUpdate;
}

@freezed
class CheckboxCellState with _$CheckboxCellState {
  const factory CheckboxCellState({
    required CellData cellData,
    required bool isSelected,
  }) = _CheckboxCellState;

  factory CheckboxCellState.initial(CellData cellData) {
    return CheckboxCellState(cellData: cellData, isSelected: _isSelected(cellData.cell));
  }
}

bool _isSelected(Cell? cell) {
  final content = cell?.content ?? "";
  return content == "Yes";
}
