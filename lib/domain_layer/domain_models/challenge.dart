class Challenge {
  final String id;
  final String heading;
  final String description;
  final String img;
  final int remainingTime;
  final String? reward;
  final String status;
  final Post? post;

  Challenge({
    required this.id,
    required this.heading,
    required this.description,
    required this.img,
    required this.remainingTime,
    this.reward,
    required this.status,
    this.post,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'],
      heading: json['heading'],
      description: json['description'],
      img: json['img'] ?? '',
      remainingTime: json['remaining_time'] ?? 0,
      reward: json['reward'],
      status: json['status'],
      post: json['post'] != null ? Post.fromJson(json['post']) : null,
    );
  }

}

class Post {
  final String id;
  final PostUser user;
  final String description;
  final List<String> images;
   int likesCount;
  final int commentsCount;
  final List<PostLike> likes;
  final List<PostComment> comments;
   bool likedByMe;
  final String createdDate;
  final String createdTime;
  final int isPublic;
  final int copyrightConsent;

  Post({
    required this.id,
    required this.user,
    required this.description,
    required this.images,
    required this.likesCount,
    required this.commentsCount,
    required this.likes,
    required this.comments,
    required this.likedByMe,
    required this.createdDate,
    required this.createdTime,
    required this.isPublic,
    required this.copyrightConsent,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      user: PostUser.fromJson(json['user']),
      description: json['description'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      likes: (json['likes'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .map((e) => PostLike.fromJson(e))
          .toList() ?? [],
      comments: (json['comments'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .map((e) => PostComment.fromJson(e))
          .toList() ?? [],
      likedByMe: json['liked_by_me'] ?? false,
      createdDate: json['created_date'] ?? '',
      createdTime: json['created_time'] ?? '',
      isPublic: json['public'] ?? 0,
      copyrightConsent: json['copyright_consent'] ?? 0,
    );
  }
}

class PostUser {
  final String id;
  final String name;
  final String firstName;
  final String countryCode;
  final String countryName;
  final String departmentName;
  final String departmentShortcut;
  final String departmentGroupName;

  PostUser({
    required this.id,
    required this.name,
    required this.firstName,
    required this.countryCode,
    required this.countryName,
    required this.departmentName,
    required this.departmentShortcut,
    required this.departmentGroupName,
  });

  factory PostUser.fromJson(Map<String, dynamic> json) {
    return PostUser(
      id: json['id'],
      name: json['name'],
      firstName: json['first_name'],
      countryCode: json['country_code'],
      countryName: json['country_name'],
      departmentName: json['department_name'],
      departmentShortcut: json['department_shortcut'],
      departmentGroupName: json['department_group_name'],
    );
  }

  factory PostUser.empty() {
    return PostUser(
      id: '',
      name: '',
      firstName: '',
      countryCode: '',
      countryName: '',
      departmentName: '',
      departmentShortcut: '',
      departmentGroupName: '',
    );
  }
}

class PostComment {
  final String id;
  final PostUser user;
  final String content;
  final bool ownComment;
  final String createdDate;
  final String createdTime;

  PostComment({
    required this.id,
    required this.user,
    required this.content,
    required this.ownComment,
    required this.createdDate,
    required this.createdTime,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) {
    return PostComment(
      id: json['id'],
      user: json['user'] is Map<String, dynamic>
          ? PostUser.fromJson(json['user'])
          : PostUser.empty(),
      content: json['content'],
      ownComment: json['own_comment'],
      createdDate: json['created_date'],
      createdTime: json['created_time'],
    );
  }
}

class PostLike {
  final String id;
  final PostUser user;

  PostLike({
    required this.id,
    required this.user,
  });

  factory PostLike.fromJson(Map<String, dynamic> json) {
    return PostLike(
      id: json['id'],
      user: json['user'] is Map<String, dynamic>
          ? PostUser.fromJson(json['user'])
          : PostUser.empty(),

    );
  }

}

