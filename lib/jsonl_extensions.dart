/// Convenience extensions for decoding and converting JSONL strings.
///
/// Model methods such as `Post.fromJsonl` and `post.toJsonl` are declared
/// by the application model; they are not package extensions.
library jsonl_extensions;

export 'src/exceptions/jsonl_format_exception.dart';
export 'src/extensions/jsonl_object_extensions.dart';
