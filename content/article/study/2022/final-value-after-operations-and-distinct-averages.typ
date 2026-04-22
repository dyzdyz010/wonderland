#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "做题思路——执行操作后的变量值 & 不同的平均值数目",
  desc: [2011. 执行操作后的变量值 难度：简单 题目： 存在一种仅支持 4 种操作和 1 个变量 X 的编程],
  date: "2022-12-23",
  tags: (
    blog-tags.algorithm,
  ),
)

= 2011. 执行操作后的变量值

== 难度：简单

== 题目：

存在一种仅支持 4 种操作和 1 个变量 `X` 的编程语言：

- `++X` 和 `X++` 使变量 `X` 的值 *加* `1`
- `--X` 和 `X--` 使变量 `X` 的值 *减* `1`

最初，`X` 的值是 `0`

给你一个字符串数组 `operations` ，这是由操作组成的一个列表，返回执行所有操作后， `X` 的 *最终值* 。

*示例 1：*

```ini
输入： operations = ["--X","X++","X++"]
输出： 1
解释： 操作按下述步骤执行：
最初，X = 0
--X：X 减 1 ，X =  0 - 1 = -1
X++：X 加 1 ，X = -1 + 1 =  0
X++：X 加 1 ，X =  0 + 1 =  1
```

*示例 2：*

```ini
输入： operations = ["++X","++X","X++"]
输出： 3
解释： 操作按下述步骤执行： 
最初，X = 0
++X：X 加 1 ，X = 0 + 1 = 1
++X：X 加 1 ，X = 1 + 1 = 2
X++：X 加 1 ，X = 2 + 1 = 3
```

*示例 3：*

```ini
输入： operations = ["X++","++X","--X","X--"]
输出： 0
解释： 操作按下述步骤执行：
最初，X = 0
X++：X 加 1 ，X = 0 + 1 = 1
++X：X 加 1 ，X = 1 + 1 = 2
--X：X 减 1 ，X = 2 - 1 = 1
X--：X 减 1 ，X = 1 - 1 = 0
```

*提示：*

- `1 <= operations.length <= 100`
- `operations[i]` 将会是 `"++X"`、`"X++"`、`"--X"` 或 `"X--"`

#line(length: 100%)

= 个人思路

== 1.模拟

初始时令 x=0，遍历字符串数组 operations，遇到 “++X" 或 “X++"时，将 x 加 1，否则将 x 减 1。

```cpp
class Solution {
public:
    int finalValueAfterOperations(vector<string>& operations) {
        int x = 0;
        for (auto &op : operations) {
            if (op == "X++" || op == "++X") {
                x++;
            } else {
                x--;
            }
        }
        return x;
    }
};
```

```cpp
class Solution {
public:
    int finalValueAfterOperations(vector<string>& operations) {
        int t = 0;
        for(auto &operation:operations){
            switch(operation[1]){
                case '+': t++;break;
                default: t--;break;
            }
        }
        return t;
    }
};
```

#line(length: 100%)

= 2465. 不同的平均值数目

== 难度：简单

== 题目：

给你一个下标从 *0* 开始长度为 *偶数* 的整数数组 `nums` 。

只要 `nums` *不是* 空数组，你就重复执行以下步骤：

- 找到 `nums` 中的最小值，并删除它。
- 找到 `nums` 中的最大值，并删除它。
- 计算删除两数的平均值。

两数 `a` 和 `b` 的 *平均值* 为 `(a + b) / 2` 。

- 比方说，`2` 和 `3` 的平均值是 `(2 + 3) / 2 = 2.5` 。

返回上述过程能得到的 *不同* 平均值的数目。

*注意* ，如果最小值或者最大值有重复元素，可以删除任意一个。

*示例 1：*

```ini
输入： nums = [4,1,4,0,3,5]
输出： 2
解释：
1. 删除 0 和 5 ，平均值是 (0 + 5) / 2 = 2.5 ，现在 nums = [4,1,4,3] 。
2. 删除 1 和 4 ，平均值是 (1 + 4) / 2 = 2.5 ，现在 nums = [4,3] 。
3. 删除 3 和 4 ，平均值是 (3 + 4) / 2 = 3.5 。
2.5 ，2.5 和 3.5 之中总共有 2 个不同的数，我们返回 2 。
```

*示例 2：*

```ini
输入： nums = [1,100]
输出： 1
解释：
删除 1 和 100 后只有一个平均值，所以我们返回 1 。
```

*提示：*

- `2 <= nums.length <= 100`
- `nums.length` 是偶数。
- `0 <= nums[i] <= 100`

#line(length: 100%)

= 个人思路

== 1.

思路
原方法：使用hashmap保存nums中的元素，每次迭代寻找数组中的最小值及最大值，将平均值存入hashset后将最小值及最大值从hashmap中删去，重复上述过程直至hashmap为空。

复杂度：O(n^2)O(n)

改进方法：首先对数组nums排序，然后用双指针依次遍历最小值和最大值

复杂度：O(nlog(n))O(n)

```cpp
class Solution {
public:
    int distinctAverages(vector<int>& nums) {
        unordered_set<double> ust;
        unordered_map<int, int> ump;
        for (auto& x : nums) {
            ++ump[x];
        }
        int mx = INT_MIN, mi = INT_MAX;
        while (!ump.empty()) {
            mx = INT_MIN, mi = INT_MAX;
            for (auto& val : nums) {
                if (!ump.count(val)) {
                    continue;
                }
                mx = max(mx, val);
                mi = min(mi, val);
            }
            if (--ump[mx] == 0) {
                ump.erase(mx);
            }
            if (--ump[mi] == 0) {
                ump.erase(mi);
            }
            ust.insert(double(mx + mi) / 2.0);
        }
        return ust.size();
    }
};
```

每天记录一下做题思路。
