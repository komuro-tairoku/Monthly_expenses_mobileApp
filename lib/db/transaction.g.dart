// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 1;

  @override
  Transaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Transaction(
      id: fields[0] as String,
      category: fields[1] as String,
      amount: fields[2] as double,
      note: fields[3] as String,
      date: fields[4] as DateTime,
      isSynced: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.category)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.note)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
