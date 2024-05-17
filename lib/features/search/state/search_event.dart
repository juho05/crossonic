part of 'search_bloc.dart';

sealed class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object> get props => [];
}

class SearchTextChanged extends SearchEvent {
  final String text;
  const SearchTextChanged(this.text);
}

class SearchTypeChanged extends SearchEvent {
  final SearchType type;
  const SearchTypeChanged(this.type);
}
