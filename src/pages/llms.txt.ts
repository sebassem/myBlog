import type { APIContext } from 'astro';
import { SITE } from '../config/site';
import { formatDate, getPostExcerpt, getPostUrl, getPublishedPosts } from '../utils/posts';

export async function GET(context: APIContext) {
  const posts = await getPublishedPosts();
  const baseUrl = (context.site?.toString() ?? SITE.url).replace(/\/$/, '');

  const lines: string[] = [
    `# ${SITE.title}`,
    '',
    `> ${SITE.description}`,
    '',
    `- Author: ${SITE.author} (${SITE.authorRole})`,
    `- Portfolio: ${SITE.portfolioUrl}`,
    `- Blog: ${baseUrl}/`,
    `- RSS Feed: ${baseUrl}/rss.xml`,
    `- Sitemap: ${baseUrl}/sitemap-index.xml`,
    '',
    '## Main Sections',
    '',
    `- [All Articles](${baseUrl}/blogs/)`,
    `- [Posts](${baseUrl}/categories/posts/)`,
    `- [AI Articles](${baseUrl}/tags/ai/)`,
    `- [Community](${baseUrl}/categories/community/)`,
    `- [About](${baseUrl}/about/)`,
    '',
    `## Articles (${posts.length})`,
    '',
    ...posts.map((post) => {
      const url = `${baseUrl}${getPostUrl(post)}`;
      const date = formatDate(post.data.date);
      const excerpt = getPostExcerpt(post, 140);
      return `- [${post.data.title}](${url}) (${date}): ${excerpt}`;
    }),
    '',
  ];

  return new Response(lines.join('\n'), {
    headers: {
      'Content-Type': 'text/plain; charset=utf-8',
    },
  });
}
