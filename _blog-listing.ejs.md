```{=html}
<%
// Curly quotes in titles and summaries, as Pandoc sets them in the posts.
const smart = (s) => String(s)
  .replace(/(^|[\s(\[{])"/g, '$1\u201c').replace(/"/g, '\u201d')
  .replace(/(^|[\s(\[{\u201c])'/g, '$1\u2018').replace(/'/g, '\u2019');
%>
<div class="blog-list">
<% for (const item of items) { %>
<article class="blog-entry<%= item.image ? '' : ' blog-entry-no-image' %>">
<% if (item.image) { %>
  <a class="blog-thumbnail" href="<%- item.path %>" tabindex="-1" aria-hidden="true">
    <img src="<%- item.image %>" alt="" loading="lazy" decoding="async">
  </a>
<% } %>
  <div class="blog-copy">
    <h2 class="no-anchor"><a href="<%- item.path %>"><%= smart(item.title) %></a></h2>
    <p class="blog-date"><%= item.date %></p>
<% if (item.description) { %>
    <div class="blog-description"><%= smart(item.description) %></div>
<% } %>
<% if (item.categories && item.categories.length) { %>
    <ul class="blog-topics" aria-label="Topics">
<% for (const category of item.categories) { %>
      <li><%= category %></li>
<% } %>
    </ul>
<% } %>
    <a class="blog-read" href="<%- item.path %>">Read post <span aria-hidden="true">→</span><span class="visually-hidden">: <%= smart(item.title) %></span></a>
  </div>
</article>
<% } %>
</div>
```
