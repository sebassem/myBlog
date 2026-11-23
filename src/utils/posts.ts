import { getCollection, type CollectionEntry } from 'astro:content';

export type BlogPost = CollectionEntry<'blogs'>;

/**
 * Matches Hugo's `urlize` / default path slugification for exact URL parity:
 * - Lowercases each path segment
 * - Replaces spaces & runs of non-alphanumeric chars (except hyphens/underscores) with `-`
 * - Collapses multiple hyphens and trims leading/trailing hyphens
 */
export function hugoUrlize(input: string): string {
  return input
    .trim()
    .toLowerCase()
    .replace(/&/g, '')
    .replace(/[^a-z0-9\s_-]+/g, '')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '');
}

/**
 * Computes the URL slug under `/blogs/` matching Hugo's permalink structure.
 * e.g. `src/content/blogs/BookReviews/Tiny -Habits.md` -> `bookreviews/tiny-habits`
 */
export function getPostSlug(post: BlogPost): string {
  const rawId = post.id.replace(/\.md$/i, '');
  return rawId
    .split('/')
    .map((segment) => hugoUrlize(segment))
    .join('/');
}

export function getPostUrl(post: BlogPost): string {
  return `/blogs/${getPostSlug(post)}/`;
}

export function getCategorySlug(category: string): string {
  return hugoUrlize(category);
}

export function getTagSlug(tag: string): string {
  return hugoUrlize(tag);
}

export function normalizeImageUrl(img?: string): string | undefined {
  if (!img) return undefined;
  if (img.startsWith('http://') || img.startsWith('https://') || img.startsWith('/')) {
    return img;
  }
  return `/${img}`;
}

export function getPostCoverImage(post: BlogPost): string | undefined {
  return normalizeImageUrl(post.data.images?.[0]);
}

export function getReadingTimeMinutes(body?: string): number {
  if (!body) return 1;
  const plain = body
    .replace(/```[\s\S]*?```/g, ' ')
    .replace(/<[^>]+>/g, ' ')
    .replace(/[#*_`>\[\]()!]/g, ' ');
  const words = plain.trim().split(/\s+/).filter(Boolean).length;
  return Math.max(1, Math.ceil(words / 220));
}

export function getPostExcerpt(post: BlogPost, maxLength = 155): string {
  if (post.data.description) return post.data.description;
  const body = post.body ?? '';
  const cleaned = body
    .replace(/<!--more-->/gi, ' ')
    .replace(/```[\s\S]*?```/g, ' ')
    .replace(/!\[[^\]]*\]\([^)]*\)/g, ' ')
    .replace(/\[([^\]]+)\]\([^)]*\)/g, '$1')
    .replace(/<[^>]+>/g, ' ')
    .replace(/^#+\s+.*$/gm, ' ')
    .replace(/[*_`>#~|-]+/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();

  if (cleaned.length <= maxLength) return cleaned;
  return cleaned.slice(0, maxLength).replace(/\s+\S*$/, '') + '…';
}

export function formatDate(date: Date): string {
  return new Intl.DateTimeFormat('en-US', {
    month: 'short',
    day: '2-digit',
    year: 'numeric',
  }).format(date);
}

export async function getPublishedPosts(): Promise<BlogPost[]> {
  const posts = await getCollection('blogs', ({ data }) => !data.draft);
  return posts.sort((a, b) => b.data.date.getTime() - a.data.date.getTime());
}

export function getRelatedPosts(current: BlogPost, allPosts: BlogPost[], count = 3): BlogPost[] {
  const currentTags = new Set((current.data.tags ?? []).map((t) => t.toLowerCase()));
  const currentCats = new Set((current.data.categories ?? []).map((c) => c.toLowerCase()));

  return allPosts
    .filter((p) => p.id !== current.id)
    .map((post) => {
      const tagMatches = (post.data.tags ?? []).filter((t) =>
        currentTags.has(t.toLowerCase())
      ).length;
      const catMatches = (post.data.categories ?? []).filter((c) =>
        currentCats.has(c.toLowerCase())
      ).length;
      return { post, score: tagMatches * 3 + catMatches };
    })
    .sort((a, b) => {
      if (b.score !== a.score) return b.score - a.score;
      return b.post.data.date.getTime() - a.post.data.date.getTime();
    })
    .slice(0, count)
    .map((item) => item.post);
}

export function getCategoryColor(category: string): 'blue' | 'pink' | 'yellow' {
  const slug = getCategorySlug(category);
  if (slug === 'contributions') return 'pink';
  if (slug === 'azure-unboxing') return 'yellow';
  return 'blue';
}

export function getCategoryDisplayName(slug: string): string {
  const map: Record<string, string> = {
    posts: 'Posts',
    contributions: 'Contributions',
    'azure-unboxing': 'Azure Unboxing',
    'book-reviews': 'Book Reviews',
  };
  return (
    map[slug] ??
    slug
      .split('-')
      .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
      .join(' ')
  );
}
