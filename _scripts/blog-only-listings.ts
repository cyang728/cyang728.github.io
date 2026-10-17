// Post-render: keep post category links pointing at the blog index.
//
// Quarto's browser script links a post's categories to the first page in
// listings.json that lists the post. The home page's "Latest writing"
// listing would come first and send readers to a page with no topic filter,
// so keep only the blog index in that file.
const outDir = Deno.env.get("QUARTO_PROJECT_OUTPUT_DIR") ?? "docs";
const file = `${outDir}/listings.json`;
try {
  const listings: { listing: string; items: string[] }[] = JSON.parse(Deno.readTextFileSync(file));
  const blog = listings.filter((l) => l.listing === "/blog.html");
  Deno.writeTextFileSync(file, JSON.stringify(blog, null, 2) + "\n");
} catch (e) {
  if (!(e instanceof Deno.errors.NotFound)) throw e;
}
