import type { APIContext } from 'astro';
import { SITE } from '../config/site';
import {
  getPostCoverImage,
  getPostExcerpt,
  getPostUrl,
  getPublishedPosts,
} from '../utils/posts';

export async function GET(context: APIContext) {
  const posts = await getPublishedPosts();
  const baseUrl = (context.site?.toString() ?? SITE.url).replace(/\/$/, '');

  const payload = posts.map((post) => {
    const cover = getPostCoverImage(post) ?? SITE.ogImage;
    const image = cover.startsWith('http') ? cover : `${baseUrl}${cover}`;
    return {
      title: post.data.title,
      url: `${baseUrl}${getPostUrl(post)}`,
      image,
      date: post.data.date.toISOString().slice(0, 10),
      description: getPostExcerpt(post, 155),
      categories: post.data.categories ?? [],
      tags: post.data.tags ?? [],
    };
  });

  return new Response(JSON.stringify(payload, null, 2), {
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
    },
  });
}
