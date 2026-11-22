import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yoru/core/error/exceptions.dart';
import 'package:yoru/core/source/local/comic_file_name.dart';
import 'package:yoru/core/source/local/local_library.dart';
import 'package:yoru/core/source/local/local_source.dart';

/// A CBZ at [path] with [files] (name → content).
void writeZip(String path, Map<String, String> files) {
  final archive = Archive();
  for (final MapEntry(:key, :value) in files.entries) {
    archive.addFile(ArchiveFile.bytes(key, utf8.encode(value)));
  }
  File(path).writeAsBytesSync(ZipEncoder().encode(archive));
}

void main() {
  group('ComicFileName', () {
    ComicFileName parse(String name) => ComicFileName.parse(name);

    test('reads chapter numbers in the usual spellings', () {
      for (final (name, series, number) in [
        ('One Piece - Ch. 012.cbz', 'One Piece', 12.0),
        ('One Piece Chapter 12.5.cbz', 'One Piece', 12.5),
        ('Solo_Leveling_ch_3.zip', 'Solo Leveling', 3.0),
        ('[Group] Blue Box #4 (2021).cbz', 'Blue Box', 4.0),
        ('Dandadan 007.cbz', 'Dandadan', 7.0),
        ('Berserk Vol. 2 Ch. 10.cbz', 'Berserk', 10.0),
      ]) {
        final result = parse(name);
        expect(result.series, series, reason: name);
        expect(result.number, number, reason: name);
        expect(result.isVolume, isFalse, reason: name);
      }
    });

    test('reads volumes', () {
      final result = parse('Monster v03.cbz');
      expect(result.series, 'Monster');
      expect(result.number, 3);
      expect(result.isVolume, isTrue);
    });

    test('a name without a number is the series', () {
      final result = parse('My Oneshot.cbz');
      expect(result.series, 'My Oneshot');
      expect(result.number, isNull);
    });

    test('a bare number keeps it as the name', () {
      final result = parse('012.cbz');
      expect(result.series, '012');
      expect(result.number, 12);
    });
  });

  test('ComicInfo reads the fields the app uses', () {
    final info = ComicInfo.parse('''
<?xml version="1.0"?>
<ComicInfo>
  <Series>Tom &amp; Jerry</Series>
  <Title>The Chase</Title>
  <Number>3</Number>
  <Volume>1</Volume>
  <Summary>Cat &lt;3 mouse</Summary>
  <Writer>A. Writer, B. Writer</Writer>
  <Penciller>A. Writer; C. Artist</Penciller>
  <Genre>Comedy, Slice of Life</Genre>
</ComicInfo>''');
    expect(info.series, 'Tom & Jerry');
    expect(info.title, 'The Chase');
    expect(info.number, 3);
    expect(info.volume, 1);
    expect(info.summary, 'Cat <3 mouse');
    expect(info.authors, ['A. Writer', 'B. Writer', 'C. Artist']);
    expect(info.genres, ['Comedy', 'Slice of Life']);
  });

  test('slugs are ASCII, stable, and apart for other scripts', () {
    final a = LocalSeries.slugFor('One Piece');
    expect(a, startsWith('one-piece-'));
    expect(LocalSeries.slugFor('  one piece '), a);
    final b = LocalSeries.slugFor('ワンピース');
    final c = LocalSeries.slugFor('進撃の巨人');
    expect(b, startsWith('comic-'));
    expect(b, isNot(c));
    expect(b.codeUnits.every((u) => u < 128), isTrue);
  });

  group('import', () {
    late Directory temp;
    late String root;
    late String inbox;

    setUp(() {
      temp = Directory.systemTemp.createTempSync('yoru_local_');
      root = '${temp.path}/library';
      inbox = '${temp.path}/inbox';
      Directory(inbox).createSync();
    });

    tearDown(() => temp.deleteSync(recursive: true));

    LocalSeries read(String title) {
      final slug = LocalSeries.slugFor(title);
      return LocalSeries.fromJson(
        jsonDecode(File('$root/$slug/series.json').readAsStringSync())
            as Map<String, dynamic>,
      );
    }

    test('a CBZ becomes a chapter, pages in natural order', () {
      writeZip('$inbox/Blue Box - Ch. 2.cbz', {
        'p10.jpg': 'ten',
        'p2.jpg': 'two',
        'p1.jpg': 'one',
        '__MACOSX/._p1.jpg': 'junk',
        'notes.txt': 'skip',
      });
      final result = importComics(root, ['$inbox/Blue Box - Ch. 2.cbz']);
      expect(result.chapters, 1);
      expect(result.series, ['Blue Box']);
      expect(result.skipped, isEmpty);

      final series = read('Blue Box');
      final chapter = series.chapters.single;
      expect(chapter.number, 2);
      expect(chapter.pages, ['000.jpg', '001.jpg', '002.jpg']);
      final dir = '$root/${series.slug}/${chapter.dir}';
      expect(
        [for (final p in chapter.pages) File('$dir/$p').readAsStringSync()],
        ['one', 'two', 'ten'],
      );
      expect(series.cover, 'cover.jpg');
      expect(File('$root/${series.slug}/cover.jpg').readAsStringSync(), 'one');
    });

    test('ComicInfo names the series and fills the details', () {
      writeZip('$inbox/whatever.cbz', {
        'ComicInfo.xml':
            '<ComicInfo><Series>Real Name</Series><Number>5</Number>'
            '<Title>Five</Title><Writer>Someone</Writer>'
            '<Summary>About it</Summary><Genre>Drama</Genre></ComicInfo>',
        '01.png': 'a',
      });
      importComics(root, ['$inbox/whatever.cbz']);
      final series = read('Real Name');
      expect(series.author, 'Someone');
      expect(series.synopsis, 'About it');
      expect(series.genres, ['Drama']);
      expect(series.chapters.single.number, 5);
      expect(series.chapters.single.title, 'Five');
    });

    test('later imports add chapters to the same series', () {
      writeZip('$inbox/Dandadan 001.cbz', {'a.jpg': '1'});
      writeZip('$inbox/Dandadan 002.cbz', {'a.jpg': '2'});
      importComics(root, ['$inbox/Dandadan 002.cbz']);
      importComics(root, ['$inbox/Dandadan 001.cbz']);
      final series = read('Dandadan');
      expect([for (final c in series.chapters) c.number], [2, 1]);
      // The cover is the lowest chapter's first page.
      expect(File('$root/${series.slug}/cover.jpg').readAsStringSync(), '1');
    });

    test('re-importing a chapter replaces it', () {
      writeZip('$inbox/X Ch 1.cbz', {'a.jpg': 'old', 'b.jpg': 'old'});
      importComics(root, ['$inbox/X Ch 1.cbz']);
      writeZip('$inbox/X Ch 1.cbz', {'a.jpg': 'new'});
      importComics(root, ['$inbox/X Ch 1.cbz']);
      final chapter = read('X').chapters.single;
      expect(chapter.pages, ['000.jpg']);
    });

    test('a ZIP of chapter folders is a whole series', () {
      writeZip('$inbox/Monster.zip', {
        'Monster/Chapter 2/1.jpg': 'b',
        'Monster/Chapter 1/1.jpg': 'a',
        'Monster/Chapter 1/2.jpg': 'a2',
      });
      final result = importComics(root, ['$inbox/Monster.zip']);
      expect(result.chapters, 2);
      final series = read('Monster');
      expect([for (final c in series.chapters) c.number], [2, 1]);
      expect(series.chapters.last.pages, hasLength(2));
    });

    test('folders: images are a chapter, chapter folders a series', () {
      final series = Directory('$inbox/Vinland')..createSync();
      for (final ch in ['Ch 1', 'Ch 2']) {
        Directory('${series.path}/$ch').createSync();
        File('${series.path}/$ch/01.webp').writeAsStringSync(ch);
      }
      writeZip('${series.path}/Vinland Ch 3.cbz', {'01.jpg': 'Ch 3'});
      final result = importComics(root, [series.path]);
      expect(result.chapters, 3);
      expect([for (final c in read('Vinland').chapters) c.number], [3, 2, 1]);
    });

    test('importing into a comic ignores the file names', () {
      writeZip('$inbox/Dandadan 001.cbz', {'a.jpg': '1'});
      importComics(root, ['$inbox/Dandadan 001.cbz']);
      final slug = LocalSeries.slugFor('Dandadan');
      writeZip('$inbox/scan_0007.cbz', {'a.jpg': '7'});
      writeZip('$inbox/Something Else.cbz', {
        'ComicInfo.xml': '<ComicInfo><Series>Other</Series></ComicInfo>',
        'a.jpg': 'x',
      });
      final result = importComics(root, [
        '$inbox/scan_0007.cbz',
        '$inbox/Something Else.cbz',
      ], into: slug);
      expect(result.slugs, [slug]);
      // Numbered from the name, else the next number.
      expect([for (final c in read('Dandadan').chapters) c.number], [8, 7, 1]);
      expect(Directory(root).listSync(), hasLength(1));
    });

    test('a renamed series still takes imports under its old title', () async {
      writeZip('$inbox/Old Name Ch 1.cbz', {'a.jpg': '1'});
      importComics(root, ['$inbox/Old Name Ch 1.cbz']);
      final slug = LocalSeries.slugFor('Old Name');
      final library = LocalLibrary(root: () async => root);
      await library.edit(
        slug,
        title: 'New Name',
        author: ' Someone ',
        synopsis: '',
        genres: ['Drama', ' ', 'Mystery '],
      );
      var series = (await library.find(slug))!;
      expect(series.title, 'New Name');
      expect(series.aliases, ['Old Name']);
      expect(series.author, 'Someone');
      expect(series.synopsis, isNull);
      expect(series.genres, ['Drama', 'Mystery']);

      for (final name in ['Old Name Ch 2.cbz', 'New Name Ch 3.cbz']) {
        writeZip('$inbox/$name', {'a.jpg': name});
        importComics(root, ['$inbox/$name']);
      }
      series = read('Old Name');
      expect(series.slug, slug);
      expect(series.title, 'New Name');
      expect([for (final c in series.chapters) c.number], [3, 2, 1]);
      expect(Directory(root).listSync(), hasLength(1));
    });

    test('a picked cover stays until the first page is asked for', () async {
      writeZip('$inbox/Cov Ch 2.cbz', {'a.jpg': 'two'});
      importComics(root, ['$inbox/Cov Ch 2.cbz']);
      final slug = LocalSeries.slugFor('Cov');
      final library = LocalLibrary(root: () async => root);
      File('$inbox/art.png').writeAsStringSync('art');
      await library.setCover(slug, '$inbox/art.png');
      expect(read('Cov').cover, 'cover-custom.png');
      expect(File('$root/$slug/cover.jpg').existsSync(), isFalse);

      // A lower chapter would change the automatic cover, not a picked one.
      writeZip('$inbox/Cov Ch 1.cbz', {'a.jpg': 'one'});
      importComics(root, ['$inbox/Cov Ch 1.cbz']);
      expect(read('Cov').cover, 'cover-custom.png');

      await library.setCover(slug, null);
      final series = read('Cov');
      expect(series.cover, 'cover.jpg');
      expect(File('$root/$slug/cover.jpg').readAsStringSync(), 'one');
      expect(File('$root/$slug/cover-custom.png').existsSync(), isFalse);
      expect(series.coverAt, isNotNull);
    });

    test('files that are not comics are skipped with a reason', () {
      File('$inbox/song.mp3').writeAsStringSync('x');
      writeZip('$inbox/empty.cbz', {'readme.txt': 'x'});
      File('$inbox/broken.cbz').writeAsStringSync('not a zip');
      final result = importComics(root, [
        '$inbox/song.mp3',
        '$inbox/empty.cbz',
        '$inbox/broken.cbz',
      ]);
      expect(result.chapters, 0);
      expect(result.skipped.map((s) => s.name), [
        'song.mp3',
        'empty.cbz',
        'broken.cbz',
      ]);
      expect(Directory(root).existsSync(), isFalse);
    });
  });

  group('LocalSource', () {
    late Directory temp;
    late LocalLibrary library;
    late LocalSource source;

    setUp(() {
      temp = Directory.systemTemp.createTempSync('yoru_local_');
      library = LocalLibrary(root: () async => temp.path);
      source = LocalSource(library);
    });

    tearDown(() => temp.deleteSync(recursive: true));

    Future<void> add(String name, Map<String, String> files) async {
      final path = '${temp.path}/../${temp.uri.pathSegments.last}-$name';
      writeZip(path, files);
      await library.import([path]);
      File(path).deleteSync();
    }

    test('Home shows one section, sorted by latest update', () async {
      final features = await source.features();
      expect(features.showFeatured, isFalse);
      expect(features.latest, {
        'sort': ['updated'],
      });
      expect(features.latestLabel, 'Recently updated');
      final sort = features.groups.single;
      expect(sort.options.map((o) => o.value), ['updated', 'added', 'title']);
    });

    test('browse says when nothing is imported', () async {
      expect(
        () => source.call('browse', [
          {'page': 1},
        ]),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            localEmptyMessage,
          ),
        ),
      );
    });

    test('answers like an extension', () async {
      await add('Alpha Ch 1.cbz', {'1.jpg': 'a'});
      await add('Alpha Ch 2.cbz', {'1.jpg': 'b', '2.jpg': 'c'});
      await add('Beta Ch 1.cbz', {'1.jpg': 'd'});

      final browse = await source.call('browse', [
        {
          'page': 1,
          'query': 'alp',
          'filters': {
            'sort': ['title'],
          },
        },
      ]) as Map;
      final items = browse['items'] as List;
      expect(items, hasLength(1));
      final alpha = items.single as Map;
      expect(alpha['title'], 'Alpha');
      expect(alpha['totalChapters'], 2);
      expect(
        alpha['cover'],
        startsWith('local://${alpha['slug']}/cover.jpg?v='),
      );
      expect(browse['hasNext'], isFalse);

      final slug = alpha['slug'];
      final chapters = await source.call('chapters', [slug]) as List;
      expect([for (final c in chapters) (c as Map)['number']], [2.0, 1.0]);

      final first = await source.call('chapter', [slug, 1]) as Map;
      expect(first['prev'], isNull);
      expect(first['next'], 2.0);
      final second = await source.call('chapter', [slug, 2]) as Map;
      expect(second['prev'], 1.0);
      expect(second['next'], isNull);
      final images = (second['images'] as List).cast<String>();
      expect(images, hasLength(2));
      expect(File(images.last).readAsStringSync(), 'c');

      final detail = await source.call('series', [slug]) as Map;
      expect(detail['title'], 'Alpha');
    });

    test('a deleted comic is a 404', () async {
      await add('Gone Ch 1.cbz', {'1.jpg': 'a'});
      final slug = LocalSeries.slugFor('Gone');
      await library.delete(slug);
      expect(
        () => source.call('series', [slug]),
        throwsA(
          isA<ServerException>().having((e) => e.statusCode, 'status', 404),
        ),
      );
    });
  });
}
