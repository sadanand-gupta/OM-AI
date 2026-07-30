import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:om_ai/config/secrets.dart';

// ── Platform detection ────────────────────────────────────────────────────────

enum SocialPlatform { instagram, linkedin, twitter, youtube, unknown }

class SocialMediaDetector {
  // ── URL patterns ────────────────────────────────────────────────────────
  static final _instagramUrl = RegExp(
    r'(?:https?://)?(?:www\.)?instagram\.com/([A-Za-z0-9_.]+)',
    caseSensitive: false,
  );
  static final _linkedinUrl = RegExp(
    r'(?:https?://)?(?:www\.)?linkedin\.com/in/([A-Za-z0-9_-]+)',
    caseSensitive: false,
  );
  static final _twitterUrl = RegExp(
    r'(?:https?://)?(?:www\.)?(?:twitter|x)\.com/([A-Za-z0-9_]+)',
    caseSensitive: false,
  );
  static final _youtubeUrl = RegExp(
    r'(?:https?://)?(?:www\.)?youtube\.com/(?:@|c/|channel/|user/)([A-Za-z0-9_-]+)',
    caseSensitive: false,
  );

  // ── Natural language patterns ────────────────────────────────────────────
  // Matches: "vibeswithvinoo instagram", "my ig is vibeswithvinoo",
  //          "@vibeswithvinoo instagram", "instagram vibeswithvinoo"
  static final _igNatural = RegExp(
    r'(?:(?:my\s+)?(?:instagram|ig|insta)(?:\s+(?:is|id|handle|account|profile))?\s*[:\-]?\s*@?([A-Za-z0-9_.]{2,30}))'
    r'|(?:@?([A-Za-z0-9_.]{2,30})\s+(?:instagram|ig|insta))',
    caseSensitive: false,
  );
  static final _linkedinNatural = RegExp(
    r'(?:(?:my\s+)?linkedin(?:\s+(?:is|id|handle|account|profile))?\s*[:\-]?\s*@?([A-Za-z0-9_-]{2,40}))'
    r'|(?:@?([A-Za-z0-9_-]{2,40})\s+linkedin)',
    caseSensitive: false,
  );
  static final _twitterNatural = RegExp(
    r'(?:(?:my\s+)?(?:twitter|x)(?:\s+(?:is|id|handle|account|profile))?\s*[:\-]?\s*@?([A-Za-z0-9_]{2,20}))'
    r'|(?:@?([A-Za-z0-9_]{2,20})\s+(?:twitter|x\s+account))',
    caseSensitive: false,
  );
  static final _youtubeNatural = RegExp(
    r'(?:(?:my\s+)?youtube(?:\s+(?:is|id|handle|channel|account))?\s*[:\-]?\s*@?([A-Za-z0-9_-]{2,40}))'
    r'|(?:@?([A-Za-z0-9_-]{2,40})\s+youtube)',
    caseSensitive: false,
  );

  /// Returns detected platform and username/handle, or null if not found.
  static ({SocialPlatform platform, String handle})? detect(String message) {
    // URL patterns first (most precise)
    var m = _instagramUrl.firstMatch(message);
    if (m != null) return (platform: SocialPlatform.instagram, handle: m.group(1)!);

    m = _linkedinUrl.firstMatch(message);
    if (m != null) return (platform: SocialPlatform.linkedin, handle: m.group(1)!);

    m = _twitterUrl.firstMatch(message);
    if (m != null) return (platform: SocialPlatform.twitter, handle: m.group(1)!);

    m = _youtubeUrl.firstMatch(message);
    if (m != null) return (platform: SocialPlatform.youtube, handle: m.group(1)!);

    // Natural language patterns — pick first non-null group
    m = _igNatural.firstMatch(message);
    if (m != null) {
      final handle = m.group(1) ?? m.group(2);
      if (handle != null) return (platform: SocialPlatform.instagram, handle: handle);
    }

    m = _linkedinNatural.firstMatch(message);
    if (m != null) {
      final handle = m.group(1) ?? m.group(2);
      if (handle != null) return (platform: SocialPlatform.linkedin, handle: handle);
    }

    m = _twitterNatural.firstMatch(message);
    if (m != null) {
      final handle = m.group(1) ?? m.group(2);
      if (handle != null) return (platform: SocialPlatform.twitter, handle: handle);
    }

    m = _youtubeNatural.firstMatch(message);
    if (m != null) {
      final handle = m.group(1) ?? m.group(2);
      if (handle != null) return (platform: SocialPlatform.youtube, handle: handle);
    }

    return null;
  }
}

// ── Social media scraper ──────────────────────────────────────────────────────

class SocialMediaService {
  static const _headers = {
    'X-RapidAPI-Key': rapidApiKey,
    'Content-Type': 'application/json',
  };

  /// Fetches profile data for the given platform and handle.
  /// Returns a formatted string Claude can analyze, or null on failure.
  static Future<String?> fetchProfile(
      SocialPlatform platform, String handle) async {
    if (rapidApiKey == 'YOUR_RAPIDAPI_KEY_HERE') return null;

    try {
      switch (platform) {
        case SocialPlatform.instagram:
          return await _fetchInstagram(handle);
        case SocialPlatform.linkedin:
          return await _fetchLinkedIn(handle);
        case SocialPlatform.twitter:
          return await _fetchTwitter(handle);
        case SocialPlatform.youtube:
          return await _fetchYouTube(handle);
        case SocialPlatform.unknown:
          return null;
      }
    } catch (e) {
      debugPrint('Social media fetch error ($platform / $handle): $e');
      return null;
    }
  }

  // ── Instagram ──────────────────────────────────────────────────────────────
  // Uses: instagram-scraper-stable.p.rapidapi.com
  static Future<String?> _fetchInstagram(String username) async {
    final uri = Uri.parse(
        'https://instagram-scraper-stable.p.rapidapi.com/ig/info/?user=$username');
    final res = await http.get(uri, headers: {
      ..._headers,
      'X-RapidAPI-Host': 'instagram-scraper-stable.p.rapidapi.com',
    }).timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) {
      debugPrint('Instagram API error ${res.statusCode}: ${res.body}');
      return null;
    }
    final data = jsonDecode(res.body);
    // Handle multiple response shapes: {data:{...}}, {user:{...}}, or flat
    final d = data['data'] ?? data['user'] ?? data['graphql']?['user'] ?? data;

    final name = d['full_name'] ?? d['name'] ?? d['username'] ?? username;
    final bio = d['biography'] ?? d['bio'] ?? '';
    final followers = _fmt(d['follower_count'] ?? d['followers'] ?? d['edge_followed_by']?['count'] ?? 0);
    final following = _fmt(d['following_count'] ?? d['following'] ?? d['edge_follow']?['count'] ?? 0);
    final posts = _fmt(d['media_count'] ?? d['posts'] ?? d['edge_owner_to_timeline_media']?['count'] ?? 0);
    final verified = (d['is_verified'] ?? d['verified'] ?? false) ? 'Yes' : 'No';
    final category = d['category'] ?? d['category_name'] ?? d['business_category_name'] ?? 'N/A';
    final website = d['external_url'] ?? d['website'] ?? d['bio_links']?[0]?['url'] ?? 'N/A';
    final isPrivate = (d['is_private'] ?? d['private'] ?? false) ? 'Yes' : 'No';

    return '''
[Instagram Profile: @$username]
Name: $name
Bio: $bio
Followers: $followers
Following: $following
Posts: $posts
Verified: $verified
Category: $category
Website: $website
Private: $isPrivate
''';
  }

  // ── LinkedIn ───────────────────────────────────────────────────────────────
  // Uses: linkedin-data-api.p.rapidapi.com (free tier: 100 req/month)
  static Future<String?> _fetchLinkedIn(String username) async {
    final uri = Uri.parse(
        'https://linkedin-data-api.p.rapidapi.com/get-profile-data-by-url?url=https://www.linkedin.com/in/$username/');
    final res = await http.get(uri, headers: {
      ..._headers,
      'X-RapidAPI-Host': 'linkedin-data-api.p.rapidapi.com',
    }).timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) return null;
    final d = jsonDecode(res.body);

    final name = '${d['firstName'] ?? ''} ${d['lastName'] ?? ''}'.trim();
    final headline = d['headline'] ?? '';
    final summary = d['summary'] ?? d['about'] ?? '';
    final location = d['geo']?['full'] ?? d['location'] ?? 'N/A';
    final connections = d['connectionsCount'] ?? d['connections'] ?? 'N/A';
    final company = d['position']?[0]?['companyName'] ?? d['company'] ?? 'N/A';
    final role = d['position']?[0]?['title'] ?? d['title'] ?? 'N/A';

    // Skills
    final skills = (d['skills'] as List? ?? [])
        .take(10)
        .map((s) => s['name'] ?? s.toString())
        .join(', ');

    return '''
[LinkedIn Profile: $username]
Name: $name
Headline: $headline
Current Role: $role at $company
Location: $location
Connections: $connections
About: $summary
Top Skills: $skills
''';
  }

  // ── Twitter / X ────────────────────────────────────────────────────────────
  // Uses: twitter241.p.rapidapi.com (free tier: 500 req/month)
  static Future<String?> _fetchTwitter(String username) async {
    final uri = Uri.parse(
        'https://twitter241.p.rapidapi.com/user?username=$username');
    final res = await http.get(uri, headers: {
      ..._headers,
      'X-RapidAPI-Host': 'twitter241.p.rapidapi.com',
    }).timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body);
    final d = data['result']?['data']?['user']?['result']?['legacy'] ??
        data['data'] ??
        data;

    final name = d['name'] ?? username;
    final bio = d['description'] ?? '';
    final followers = _fmt(d['followers_count'] ?? 0);
    final following = _fmt(d['friends_count'] ?? 0);
    final tweets = _fmt(d['statuses_count'] ?? 0);
    final verified = (d['verified'] ?? false) ? 'Yes' : 'No';
    final location = d['location'] ?? 'N/A';
    final website = d['url'] ?? d['entities']?['url']?['urls']?[0]?['expanded_url'] ?? 'N/A';
    final joined = d['created_at'] ?? 'N/A';
    final likes = _fmt(d['favourites_count'] ?? 0);

    return '''
[Twitter/X Profile: @$username]
Name: $name
Bio: $bio
Followers: $followers
Following: $following
Tweets: $tweets
Likes: $likes
Verified: $verified
Location: $location
Website: $website
Joined: $joined
''';
  }

  // ── YouTube ────────────────────────────────────────────────────────────────
  // Uses: youtube-v31.p.rapidapi.com (free tier: 500 req/month)
  static Future<String?> _fetchYouTube(String handle) async {
    // First search for the channel
    final searchUri = Uri.parse(
        'https://youtube-v31.p.rapidapi.com/search?q=$handle&part=snippet&type=channel&maxResults=1');
    final searchRes = await http.get(searchUri, headers: {
      ..._headers,
      'X-RapidAPI-Host': 'youtube-v31.p.rapidapi.com',
    }).timeout(const Duration(seconds: 15));

    if (searchRes.statusCode != 200) return null;
    final searchData = jsonDecode(searchRes.body);
    final items = searchData['items'] as List?;
    if (items == null || items.isEmpty) return null;

    final channelId = items[0]['id']?['channelId'] ?? items[0]['snippet']?['channelId'];
    if (channelId == null) return null;

    // Then fetch channel details
    final detailUri = Uri.parse(
        'https://youtube-v31.p.rapidapi.com/channels?part=snippet,statistics&id=$channelId');
    final detailRes = await http.get(detailUri, headers: {
      ..._headers,
      'X-RapidAPI-Host': 'youtube-v31.p.rapidapi.com',
    }).timeout(const Duration(seconds: 15));

    if (detailRes.statusCode != 200) return null;
    final detailData = jsonDecode(detailRes.body);
    final channel = (detailData['items'] as List?)?.firstOrNull;
    if (channel == null) return null;

    final snippet = channel['snippet'] ?? {};
    final stats = channel['statistics'] ?? {};

    final name = snippet['title'] ?? handle;
    final description = snippet['description'] ?? '';
    final country = snippet['country'] ?? 'N/A';
    final created = snippet['publishedAt'] ?? 'N/A';
    final subscribers = _fmt(int.tryParse(stats['subscriberCount'] ?? '0') ?? 0);
    final views = _fmt(int.tryParse(stats['viewCount'] ?? '0') ?? 0);
    final videos = _fmt(int.tryParse(stats['videoCount'] ?? '0') ?? 0);

    return '''
[YouTube Channel: $handle]
Name: $name
Subscribers: $subscribers
Total Views: $views
Videos: $videos
Country: $country
Created: $created
Description: $description
''';
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _fmt(dynamic num) {
    final n = num is int ? num : int.tryParse(num.toString()) ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}
