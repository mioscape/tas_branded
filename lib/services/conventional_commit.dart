import 'dart:convert';
import 'dart:io';
import 'package:conventional/conventional.dart';

// ignore_for_file: avoid_print

void main() async {
  // Get the commit log using the git command
  final List<String> commitLog = await getGitCommitLog();

  // Parse commits
  final List<Commit> commits = Commit.parseCommits(commitLog.join('\n'));
  final firstCommit = commits.first;
  print(firstCommit.author.name); // "Jane Doe"
  print(firstCommit.author.email); // "jane.doe@example.com"
  print(firstCommit.breaking); // false
  print(firstCommit.type); // "fix"
  print(firstCommit.description); // "release workflow"

  // Check if we have releasable commits
  final shouldRelease = hasReleasableCommits(commits);
  print(shouldRelease); // true

  if (shouldRelease) {
    // Write to a changelog file
    writeChangelog(
      commits: commits,
      changelogFilePath: 'CHANGELOG.md',
      version: '1.2.0',
      now: DateTime.now(),
    );
  }
}

Future<List<String>> getGitCommitLog() async {
  final result = await Process.run('git', ['log', '--pretty=format:%s']);
  if (result.exitCode == 0) {
    final List<String> commitLog =
        LineSplitter.split(result.stdout as String).toList();
    return commitLog;
  } else {
    throw Exception('Failed to retrieve git commit log.');
  }
}
