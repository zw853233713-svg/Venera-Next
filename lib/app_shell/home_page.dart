import 'package:venera_next/features/favorites/favorites_scope.dart';
import 'package:venera_next/features/history/history_scope.dart';
import 'package:flutter/material.dart';
import 'package:venera_next/components/scroll.dart';
import 'package:venera_next/features/comic_source/comic_source.dart';
import 'package:venera_next/foundation/app.dart';
import 'package:venera_next/foundation/consts.dart';
import 'package:venera_next/foundation/context.dart';
import 'package:venera_next/foundation/iphone_duo_layout.dart';
import 'package:venera_next/features/history/history.dart';
import 'package:venera_next/features/favorites/favorites.dart';
import 'package:venera_next/features/local_comics/local_comics.dart';
import 'package:venera_next/features/follow_updates/follow_updates.dart';
import 'package:venera_next/features/image_favorites/image_favorites.dart';
import 'package:venera_next/features/search/search.dart';
import 'package:venera_next/features/sync/sync.dart';
import 'package:venera_next/foundation/widget_utils.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final history = HistorySummary(
      manager: HistoryScope.read(context),
      favoriteChanges: FavoritesScope.read(context),
    );
    final summaries = [
      const ReadLaterSummary(),
      const LocalComicsSummary(),
      const FollowUpdatesWidget(),
      ComicSourceSummary(manager: ComicSourceManager.current),
      const ImageFavoritesSummary(),
    ];
    final duoLandscape =
        App.isIPhoneDuo &&
        IPhoneDuoLayout.forSize(MediaQuery.sizeOf(context)) ==
            IPhoneDuoLayout.innerLandscape;
    var widget = SmoothCustomScrollView(
      slivers: [
        SliverPadding(padding: EdgeInsets.only(top: context.padding.top)),
        const SearchEntry(),
        const SyncStatusSummary(),
        if (duoLandscape)
          SliverCrossAxisGroup(
            slivers: [
              SliverCrossAxisExpanded(flex: 5, sliver: history),
              SliverCrossAxisExpanded(
                flex: 4,
                sliver: SliverMainAxisGroup(slivers: summaries),
              ),
            ],
          )
        else ...[
          history,
          ...summaries,
        ],
        SliverPadding(padding: EdgeInsets.only(top: context.padding.bottom)),
      ],
    );
    return context.width > changePoint ? widget.paddingHorizontal(8) : widget;
  }
}
