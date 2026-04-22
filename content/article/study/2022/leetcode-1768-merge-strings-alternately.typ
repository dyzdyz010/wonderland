#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "LeetCode每日一题-1768-交替合并字符串",
  desc: [题目 给你两个字符串 word1 和 word2 。请你从 word1 开始，通过交替添加字母来合并字],
  date: "2022-10-23",
  tags: (
    blog-tags.rust,
    blog-tags.algorithm,
  ),
)

== 题目

给你两个字符串 word1 和 word2 。请你从 word1 开始，通过交替添加字母来合并字符串。如果一个字符串比另一个字符串长，就将多出来的字母追加到合并后字符串的末尾。

返回*合并后的字符串*。

=== 示例 1：

```css
输入：word1 = "abc", word2 = "pqr"
输出："apbqcr"
解释：字符串合并情况如下所示：
word1：  a   b   c
word2：    p   q   r
合并后：  a p b q c r
```

=== 示例 2：

```css
输入：word1 = "ab", word2 = "pqrs"
输出："apbqrs"
解释：注意，word2 比 word1 长，"rs" 需要追加到合并后字符串的末尾。
word1：  a   b 
word2：    p   q   r   s
合并后：  a p b q   r   s
```

=== 示例 3：

```css
输入：word1 = "abcd", word2 = "pq"
输出："apbqcd"
解释：注意，word1 比 word2 长，"cd" 需要追加到合并后字符串的末尾。
word1：  a   b   c   d
word2：    p   q 
合并后：  a p b q c   d
```

== 思路

一开始的想法是，选择两个字符串中短的那个，取其长度，作为交替插入循环的次数，之后再判断哪一个字符串更长，然后将长字符串后面多余的部分再附加到结果字符串上：

```rust
impl Solution {
    pub fn merge_alternately(word1: String, word2: String) -> String {
        let len1 = word1.len();
        let len2 = word2.len();
        let sub = len2 as i32 - len1 as i32;

        let mut result: String = String::from("");

        match sub >= 0 {
            true => {
                for idx in 0..len1 {
                    result.push(word1.chars().nth(idx).unwrap());
                    result.push(word2.chars().nth(idx).unwrap());
                }
                result.extend(word2[len1 as usize..].chars());
            },
            false => {
                for idx in 0..len2 {
                    result.push(word1.chars().nth(idx).unwrap());
                    result.push(word2.chars().nth(idx).unwrap());
                }
                result.extend(word1[len2 as usize..].chars());
            }
        }

        return result;
    }
}
```

可以看到，代码中有很多重复和无用的代码，比如 `sub` 这个变量就毫无用处，完全可以直接让 `len` 和 `len2` 比较大小；而且在短长度的部分可以不进行判断，直接选择更小的长度进行循环即可：

```rust
impl Solution {
    pub fn merge_alternately(word1: String, word2: String) -> String {
        let len1 = word1.len();
        let len2 = word2.len();

        let mut result: String = String::from("");

        for idx in 0..std::cmp::min(len1, len2) {
            result.push(word1.chars().nth(idx).unwrap());
            result.push(word2.chars().nth(idx).unwrap());
        }

        match len1 > len2 {
            true => result.extend(word1[len2 as usize..].chars()),
            false => result.extend(word2[len1 as usize..].chars());
        }

        return result;
    }
}
```

有没有办法把两个过程整合在一个循环里呢？有的，可以对 `word1` 和 `word2` 分别建立循环索引，放在同一个循环内，使用条件控制是否追加下一个字符，循环条件即为索引在对应字符串长度范围内：

```rust
impl Solution {
    pub fn merge_alternately(word1: String, word2: String) -> String {
        let len1 = word1.len();
        let len2 = word2.len();

        let mut result: String = String::from("");

        let mut i = 0;
        let mut j = 0;

        while i < len1 || j < len2 {
            if i < len1 {
                result.push(word1.chars().nth(i).unwrap());
            }
            if j < len2 {
                result.push(word2.chars().nth(j).unwrap());
            }
            i += 1;
            j += 1;
        }

        return result;
    }
}
```

这样代码看着更整齐更舒服了，但是 LeetCode 显示这种方法还比上一种方法消耗内存更多……可能是增加了索引变量的缘故。

三种代码都可以AC，就这样吧。
