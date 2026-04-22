#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "N 次操作后的最大分数和",
  desc: [1799. N 次操作后的最大分数和 难度：困难 题目： 给你 nums ，它是一个大小为 2 \* n],
  date: "2022-12-22",
  tags: (
    blog-tags.algorithm,
  ),
)

= 1799. N 次操作后的最大分数和

== 难度：困难

== 题目：

给你 `nums` ，它是一个大小为 `2 * n` 的正整数数组。你必须对这个数组执行 `n` 次操作。

在第 `i` 次操作时（操作编号从 *1* 开始），你需要：

- 选择两个元素 `x` 和 `y` 。
- 获得分数 `i * gcd(x, y)` 。
- 将 `x` 和 `y` 从 `nums` 中删除。

请你返回 `n` 次操作后你能获得的分数和最大为多少。

函数 `gcd(x, y)` 是 `x` 和 `y` 的最大公约数。

*示例 1：*

```ini
输入： nums = [1,2]
输出： 1
解释： 最优操作是：
(1 * gcd(1, 2)) = 1
```

*示例 2：*

```ini
输入： nums = [3,4,6,8]
输出： 11
解释： 最优操作是：
(1 * gcd(3, 6)) + (2 * gcd(4, 8)) = 3 + 8 = 11
```

*示例 3：*

```ini
输入： nums = [1,2,3,4,5,6]
输出： 14
解释： 最优操作是：
(1 * gcd(1, 5)) + (2 * gcd(2, 4)) + (3 * gcd(3, 6)) = 1 + 4 + 9 = 14
```

*提示：*

- `1 <= n <= 7`
- `nums.length == 2 * n`
- `1 <= nums[i] <= 106`

#line(length: 100%)

= 个人思路

== 1.双指针

我们可以先预处理得到数组 nums 中任意两个数的最大公约数，存储在二维数组 g 中，其中 g\[i\]\[j\]表示 nums\[i\]和 nums\[j\]的最大公约数。

然后定义 f\[k\]表示当前操作后的状态为 kkk 时，可以获得的最大分数和。假设 mmm 为数组 nums 中的元素个数，那么状态一共有 2^m种，即 kkk 的取值范围为\[0, 2^m - 1\]。

从小到大枚举所有状态，对于每个状态 k，先判断此状态中二进制位的个数 cnt 是否为偶数，是则进行如下操作：

枚举 k 中二进制位为 1 的位置，假设为 i 和 j，则 i 和 j 两个位置的元素可以进行一次操作，此时可以获得的分数为 cnt/2\*g\[i\]\[j\]，更新 f\[k\]的最大值。

最终答案即为f\[2^m - 1\]。

```cpp
class Solution {
public:
    int maxScore(vector<int>& nums) {
        int m = nums.size();
        int g[m][m];
        for (int i = 0; i < m; ++i) {
            for (int j = i + 1; j < m; ++j) {
                g[i][j] = gcd(nums[i], nums[j]);
            }
        }
        int f[1 << m];
        memset(f, 0, sizeof f);
        for (int k = 0; k < 1 << m; ++k) {
            int cnt = __builtin_popcount(k);
            if (cnt % 2 == 0) {
                for (int i = 0; i < m; ++i) {
                    if (k >> i & 1) {
                        for (int j = i + 1; j < m; ++j) {
                            if (k >> j & 1) {
                                f[k] = max(f[k], f[k ^ (1 << i) ^ (1 << j)] + cnt / 2 * g[i][j]);
                            }
                        }
                    }
                }
            }
        }
        return f[(1 << m) - 1];
    }
};
```

#figure(image("/public/assets/img/2022/max-score-after-n-operations-1.png"), caption: "image.png")

每天记录一下做题思路。

