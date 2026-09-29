import 'package:sqflite/sqflite.dart';

import '../domain/snapshot.dart';
import '../domain/snapshot_repository.dart';

/// SQLite-backed [SnapshotRepository]. The database file lives in the app's
/// private storage and never leaves the device.
class SqfliteSnapshotRepository implements SnapshotRepository {
  SqfliteSnapshotRepository(this._db);

  static const _listFollowers = 0;
  static const _listFollowing = 1;

  final Database _db;

  /// Opens (and creates if needed) the database at [path].
  /// Pass a custom [factory] in tests (e.g. sqflite_common_ffi).
  static Future<SqfliteSnapshotRepository> open(String path, {DatabaseFactory? factory}) async {
    final f = factory ?? databaseFactory;
    final db = await f.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE snapshots (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              created_at INTEGER NOT NULL,
              follower_count INTEGER NOT NULL,
              following_count INTEGER NOT NULL,
              has_following INTEGER NOT NULL DEFAULT 1
            )''');
          await db.execute('''
            CREATE TABLE snapshot_users (
              snapshot_id INTEGER NOT NULL REFERENCES snapshots(id) ON DELETE CASCADE,
              list INTEGER NOT NULL,
              username TEXT NOT NULL,
              PRIMARY KEY (snapshot_id, list, username)
            )''');
        },
      ),
    );
    return SqfliteSnapshotRepository(db);
  }

  @override
  Future<int> saveSnapshot({
    required DateTime createdAt,
    required Set<String> followers,
    required Set<String> following,
    required bool hasFollowingData,
  }) {
    return _db.transaction((txn) async {
      final id = await txn.insert('snapshots', {
        'created_at': createdAt.millisecondsSinceEpoch,
        'follower_count': followers.length,
        'following_count': following.length,
        'has_following': hasFollowingData ? 1 : 0,
      });
      final batch = txn.batch();
      for (final u in followers) {
        batch.insert('snapshot_users', {'snapshot_id': id, 'list': _listFollowers, 'username': u});
      }
      for (final u in following) {
        batch.insert('snapshot_users', {'snapshot_id': id, 'list': _listFollowing, 'username': u});
      }
      await batch.commit(noResult: true);
      return id;
    });
  }

  @override
  Future<List<SnapshotSummary>> listSnapshots() async {
    final rows = await _db.query('snapshots', orderBy: 'created_at DESC, id DESC');
    return rows.map(_summaryFromRow).toList();
  }

  @override
  Future<Snapshot?> getSnapshot(int id) async {
    final rows = await _db.query('snapshots', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return _load(rows.first);
  }

  @override
  Future<Snapshot?> getPreviousSnapshot(int id) async {
    final current = await _db.query('snapshots', where: 'id = ?', whereArgs: [id], limit: 1);
    if (current.isEmpty) return null;
    final createdAt = current.first['created_at'] as int;
    final rows = await _db.query(
      'snapshots',
      where: 'created_at < ? OR (created_at = ? AND id < ?)',
      whereArgs: [createdAt, createdAt, id],
      orderBy: 'created_at DESC, id DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _load(rows.first);
  }

  @override
  Future<void> deleteSnapshot(int id) async {
    await _db.delete('snapshots', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> deleteAll() async {
    await _db.transaction((txn) async {
      await txn.delete('snapshot_users');
      await txn.delete('snapshots');
    });
  }

  Future<void> close() => _db.close();

  Future<Snapshot> _load(Map<String, Object?> row) async {
    final id = row['id'] as int;
    final users = await _db.query(
      'snapshot_users',
      columns: ['list', 'username'],
      where: 'snapshot_id = ?',
      whereArgs: [id],
    );
    final followers = <String>{};
    final following = <String>{};
    for (final u in users) {
      (u['list'] == _listFollowers ? followers : following).add(u['username'] as String);
    }
    return Snapshot(
      id: id,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      followers: followers,
      following: following,
      hasFollowingData: row['has_following'] == 1,
    );
  }

  SnapshotSummary _summaryFromRow(Map<String, Object?> row) => SnapshotSummary(
    id: row['id'] as int,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
    followerCount: row['follower_count'] as int,
    followingCount: row['following_count'] as int,
    hasFollowingData: row['has_following'] == 1,
  );
}
