// =============================================================================
// Footnote & Sidenote 模块
// =============================================================================
//
// 这个模块实现了响应式的脚注/旁注系统：
// - 大屏幕 (≥1280px): 显示 Tufte 风格的旁注 (sidenote)，在文本右侧边距显示
// - 小屏幕 (<1280px): 显示传统的底部脚注 (footnote)
//
// 两种形式同时渲染到 HTML，通过 CSS 响应式断点控制显示/隐藏
// =============================================================================

#import "@preview/shiroa:0.3.1": book-sys, is-html-target, is-pdf-target, is-web-target, plain-text, templates
#import templates: *
#import "mod.typ": static-heading-link
#import "code/rule.typ": code-block-rules, dash-color, is-dark-theme
#import "code/theme.typ": theme-frame
#import "target.typ": sys-is-html-target

#let is-html-target = is-html-target()
#let is-pdf-target = is-pdf-target()
#let is-web-target = is-web-target() or sys-is-html-target

// -----------------------------------------------------------------------------
// 脚注状态管理
// -----------------------------------------------------------------------------
// 使用 Typst 的 state 机制收集文档中的所有脚注
// 因为 typst.ts 可能不完全支持原生的 footnote.entry 渲染，
// 我们采用手动收集和渲染的方式
#let footnote-state = state("footnotes", ())

// -----------------------------------------------------------------------------
// web-footnote: 渲染脚注引用和旁注
// -----------------------------------------------------------------------------
// 这个函数在文本中脚注位置生成以下 HTML 结构：
//
// <span class="sidenote-wrapper">
//   <!-- 脚注引用：上标数字链接，点击跳转到底部脚注 -->
//   <a href="#footnote-1" id="footnote-ref-1" class="footnote-ref">
//     <sup>1</sup>
//   </a>
//   <!-- 旁注：大屏幕时在右侧边距显示 -->
//   <span class="sidenote" id="sidenote-1">
//     <span class="sidenote-number">1</span>
//     <span class="sidenote-content">脚注内容...</span>
//   </span>
// </span>
//
// 参数:
//   content - 脚注的内容
#let web-footnote(content) = {
  context {
    // 获取当前已收集的脚注数量，确定新脚注的编号
    let current = footnote-state.get()
    let idx = current.len() + 1
    
    // 将内容转换为纯文本（用于 HTML 渲染）
    let content-text = plain-text(content)
    
    // 将脚注信息存入状态，供底部脚注区域使用
    footnote-state.update(arr => arr + ((idx: idx, content: content-text),))

    // 生成包装元素，同时包含脚注引用和旁注
    html.elem(
      "span",
      attrs: (class: "sidenote-wrapper"),
      {
        // ===== 脚注引用 (所有屏幕尺寸都渲染) =====
        // 渲染上标数字，链接到底部脚注
        html.elem(
          "a",
          attrs: (
            href: "#footnote-" + str(idx),      // 链接到底部脚注
            id: "footnote-ref-" + str(idx),     // 用于从底部脚注返回
            class: "footnote-ref",
          ),
          html.elem("sup", str(idx)),
        )
        
        // ===== 旁注 (仅大屏幕显示，通过 CSS 控制) =====
        // 在脚注引用旁边渲染旁注内容
        // CSS 会将其定位到右侧边距，并在小屏幕时隐藏
        html.elem(
          "span",
          attrs: (
            class: "sidenote",
            id: "sidenote-" + str(idx),
          ),
          {
            // 旁注编号
            html.elem("span", attrs: (class: "sidenote-number"), str(idx))
            // 旁注内容
            html.elem("span", attrs: (class: "sidenote-content"), content-text)
          },
        )
      },
    )
  }
}

// -----------------------------------------------------------------------------
// render-footnotes: 在文档末尾渲染底部脚注区域
// -----------------------------------------------------------------------------
// 这个函数在文档末尾生成传统的脚注列表，用于小屏幕显示
// 在大屏幕上通过 CSS 隐藏（因为旁注已经可见）
//
// 生成的 HTML 结构：
//
// <hr class="footnotes-divider">
// <section class="footnotes" role="doc-endnotes">
//   <h2 class="footnotes-title">脚注</h2>
//   <ol class="footnotes-list">
//     <li id="footnote-1" class="footnote-item">
//       <div class="footnote-content">
//         <span>脚注内容...</span>
//         <a href="#footnote-ref-1" class="footnote-backref">↑</a>
//       </div>
//     </li>
//     ...
//   </ol>
// </section>
#let render-footnotes() = context {
  // 获取文档中所有收集的脚注
  let notes = footnote-state.final()
  
  // 只有存在脚注时才渲染
  if notes.len() > 0 {
    // 分隔线（大屏幕时隐藏）
    html.elem("hr", attrs: (class: "footnotes-divider"))
    
    // 脚注区域容器（大屏幕时隐藏）
    html.elem(
      "section",
      attrs: (
        class: "footnotes",
        role: "doc-endnotes",   // 无障碍访问角色
      ),
      {
        // 脚注标题
        html.elem("h2", attrs: (class: "footnotes-title"), "脚注")
        
        // 脚注有序列表
        html.elem(
          "ol",
          attrs: (class: "footnotes-list"),
          for note in notes {
            // 单个脚注项
            html.elem(
              "li",
              attrs: (
                id: "footnote-" + str(note.idx),  // 用于从引用跳转到此处
                class: "footnote-item",
              ),
              html.elem("div", attrs: (class: "footnote-content flex items-center gap-2"), {
                // 脚注内容
                html.elem(
                  "span",
                  attrs: (class: "footnote-content"),
                  note.content,
                )
                // 返回引用位置的链接（带向上箭头图标）
                html.elem(
                  "a",
                  attrs: (
                    href: "#footnote-ref-" + str(note.idx),  // 返回到正文中的引用位置
                    class: "footnote-backref flex items-center justify-center",
                  ),
                  // SVG 向上箭头图标
                  html.elem(
                    "svg",
                    attrs: (width: "24", height: "24", viewBox: "0 0 24 24"),
                    [#html.elem("path", attrs: (
                      fill: "currentColor",
                      d: "M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2M12 7l-5 5h3v4h4v-4h3z",
                    ))],
                  ),
                )
              }),
            )
          },
        )
      },
    )
  }
}
