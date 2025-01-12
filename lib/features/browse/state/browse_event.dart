part of 'browse_bloc.dart';

sealed class BrowseEvent extends Equatable {
  const BrowseEvent();

  @override
  List<Object> get props => [];
}

class SearchTextChanged extends BrowseEvent {
  final String text;
  const SearchTextChanged(this.text);
}

class BrowseTypeChanged extends BrowseEvent {
  final BrowseType type;
  const BrowseTypeChanged(this.type);
}
