export const SITE = {
  title: "Seif Bassem's Cloud Blog",
  shortTitle: 'Seif Bassem',
  description:
    'Notes on cloud architecture, Kubernetes, enterprise AI, and platform engineering by Seif Bassem.',
  author: 'Seif Bassem',
  authorRole: 'Cloud & AI Enterprise Architect',
  authorSummary:
    'This is a blog about the ☁️ Cloud, AI architecture, and some other random thoughts 📚💻📰.',
  authorImage: '/images/author.jpeg',
  ogImage: '/images/logo.jpeg',
  url: 'https://blog.seifbassem.com',
  portfolioUrl: 'https://seifbassem.com',
  postsPerPage: 12,
  analytics: {
    googleAnalyticsId: 'G-6RJ38N4B9F',
    clarityId: 'tiu6lkiav5',
  },
  forms: {
    formspreeAction: 'https://formspree.io/f/xqkwlqrn',
    mailchimpAction:
      'https://seifbassem.us6.list-manage.com/subscribe/post?u=257b2cad8c391bae63f348005&id=ebd0aabf4e',
    mailchimpBotField: 'b_257b2cad8c391bae63f348005_ebd0aabf4e',
  },
  socials: [
    {
      title: 'YouTube',
      icon: 'ri-youtube-line',
      link: 'https://www.youtube.com/@seifbassemazure/',
    },
    {
      title: 'LinkedIn',
      icon: 'ri-linkedin-line',
      link: 'https://www.linkedin.com/in/seif-bassem/',
    },
    {
      title: 'X / Twitter',
      icon: 'ri-twitter-x-line',
      link: 'https://twitter.com/SeifBassem',
    },
    {
      title: 'GitHub',
      icon: 'ri-github-line',
      link: 'https://github.com/sebassem',
    },
    {
      title: 'RSS',
      icon: 'ri-rss-line',
      link: '/rss.xml',
    },
  ],
  categories: [
    { name: 'Posts', slug: 'posts', color: 'blue' as const },
    { name: 'Community', slug: 'community', color: 'pink' as const },
    { name: 'Azure Unboxing', slug: 'azure-unboxing', color: 'yellow' as const },
    { name: 'Book Reviews', slug: 'book-reviews', color: 'blue' as const },
  ],
} as const;
