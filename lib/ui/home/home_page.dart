import 'package:auto_route/auto_route.dart';
import 'package:crossonic/ui/home/random_songs.dart';
import 'package:crossonic/ui/home/random_songs_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        children: [
          RandomSongs(
            viewModel: RandomSongsViewModel(
              subsonicRepository: context.read(),
            ),
          ),
        ],
      ),
    );
  }
}
