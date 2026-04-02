#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "机器学习-神经网络（反向传播算法）学习总结",
  desc: [机器学习-神经网络（反向传播算法）学习总结],
  date: "2017-05-17",
  tags: (
    blog-tags.ml,
    blog-tags.programming,
  ),
)

今天下午完成了Andrew Ng的机器学习课程第五周的课程，完成了自己实现一个基本神经网络的编程作业，不得不说神经网络的运算量真大啊，我的CPU温度都快上100了......

第四周与第五周共两周的内容讲了神经网络的由来和表示方法以及实现方法。

= 为什么要使用神经网络

与之前学过的逻辑回归相比，在逻辑回归的假设函数 $h_theta (x)$ 中：

$ g(z) = frac(1, 1+e^(-z)) $

$ z = theta^T x $

可以看到，$z$ 的形式是线性的，这意味着你只能拟合这样的数据：

#figure(image("/public/assets/img/2017/05/006tNc79ly1fezv6qgjh4j30ik0fw0uz.jpg"))

_即：_ 决策边界只用一次方程就可以表示

或者是这样的数据：

#figure(image("/public/assets/img/2017/05/006tNc79ly1ff07vikxvbj30si0m6dhz.jpg"))

_即：_ 特征数量不多，可以通过添加高次项的方法形成不规则的决策边界。

但是如果你需要识别一张图片中是否有车辆出现：

#figure(image("/public/assets/img/2017/05/006tKfTcly1ffgddiiuihj31bs0oi78s.jpg"))

假设用作样本的图片只有 $50 times 50$ 像素大小，这样的话你可能输入的特征数量就是 $50 times 50 = 2500$ 个...，但如果需要的决策边界是形如这样的：

#figure(image("/public/assets/img/2017/05/006tKfTcly1ffgdhtx31oj30tg0l0abd.jpg"))

你需要一个不规则的决策边界表示方法，这时你可能会引入高次项，即使只增加二次项：

$ x_i x_j $

这样的话特征数量就会变成：

$ frac((1+2500) times 2500, 2) approx 3,000,000 $

用这个数量级的特征去做逻辑回归，计算量是非常恐怖的。因此需要一种能够降低运算量的模型来避免这种问题的出现。

*神经网络(Neural Network)* 受启发于人类大脑。...

*神经元(Neuron)* 是这其中的信号传递单元：

#figure(image("/public/assets/img/2017/05/006tKfTcly1ffgduhpdk7j31800qcq76.jpg"))

受此启发，我们得到了工作方式类似的神经元模型：

#figure(image("/public/assets/img/2017/05/006tKfTcly1ffge177ljfj30ue0jg410.jpg"))

可以看到，橙色的节点接受左边三个节点的输入，并计算出我们需要的输出值 $h_theta (x)$。其中 $x_0$ 是所谓的 *偏置单元(bias unit)*。我们把输入表示为：

$ x = mat(delim: "[", x_0; x_1; x_2; x_3) quad theta = mat(delim: "[", theta_0; theta_1; theta_2; theta_3) $

其中，$x$ 代表左侧四个单元的值...$theta$ 代表每个输入值进行输入时的 *权重(weight)*...

有了神经元的模型后，我们就可以...得到了我们现在使用的分层神经网络(三层)：

#figure(image("/public/assets/img/2017/05/006tKfTcly1ffgeqy8sd4j31f60teq9m.jpg"))

有了这样的神经网络模型，我们就可以通过这样的计算来获取假设函数 $h_Theta (x)$ 的值：

$ a_1^((2)) &= g(Theta_(10)^((1)) x_0 + Theta_(11)^((1)) x_1 + Theta_(12)^((1)) x_2 + Theta_(13)^((1)) x_3) \
a_2^((2)) &= g(Theta_(20)^((1)) x_0 + Theta_(21)^((1)) x_1 + Theta_(22)^((1)) x_2 + Theta_(23)^((1)) x_3) \
a_3^((2)) &= g(Theta_(30)^((1)) x_0 + Theta_(21)^((1)) x_1 + Theta_(32)^((1)) x_2 + Theta_(33)^((1)) x_3) \
h_Theta (x) &= a_1^((3)) = g(Theta_(10)^((2)) a_0^((2)) + Theta_(11)^((2)) a_1^((2)) + Theta_(12)^((2)) a_2^((2)) + Theta_(13)^((2)) a_0^((3))) $

其中：$g(z)$ 就是我们的激活函数Sigmoid， $a_i^((l))$ 为网络中第 $l$ 层中第 $i$ 个节点的 *激活值(Activation)*，$Theta^((l))$ 为网络中第 $l$ 层的节点值向第 $l+1$ 层节点变换时的权值矩阵。如果在第 $l$ 层有 $S_l$ 个节点，在第 $l+1$ 层有 $S_(l+1)$ 个节点，那么第 $l$ 层的权值矩阵 $Theta$ 的大小为 $S_(j+1) times (S_j + 1)$。

我们进一步对上面的公式向量化：

$ z^((2)) &= Theta^((1)) a^((1)) &quad (a^((1)) = x) \
a^((2)) &= g(z^((2))) &quad (a^((2))_(3 times 1)) \
"Add" a_0^((2)) &= 1 &quad (a^((2))_(4 times 1)) \
z^((3)) &= Theta^((2)) a^((2)) \
h_Theta (x) &= a^((3)) = g(z^((3))) $

需要注意的是...比如下面这个：

#figure(image("/public/assets/img/2017/05/006tKfTcgy1ffialq260ej30yq0audiq.jpg"))

可以看到，这里面有2个隐含层，每层5个节点，输出层有4个节点...最终得到的假设函数就是这样的：

$ h_Theta (x) approx mat(delim: "[", 1; 0; 0; 0), quad h_Theta (x) approx mat(delim: "[", 0; 1; 0; 0), quad h_Theta (x) approx mat(delim: "[", 0; 0; 1; 0), quad h_Theta (x) approx mat(delim: "[", 0; 0; 0; 1) $

其表示为一个列向量，为1的位置就是最终得到的所属分类。

设样本集为：

$ {(x^((1)), y^((1))), (x^((1)), y^((1))), ..., (x^((m)), y^((m)))} $

其中，$m$ 为样本数量。我们再设 $L$ 为神经网络的总层数，$S_l$ 为第 $l$ 层包含的节点数量 *(不包括偏执单元)。* ...如果只有一个节点，即 _只将样本分为两类_，那么有 $y=0$ 或 $y=1$；如果有多个节点，...那么就有 $y in RR^K$ ($K$ 为总分类数)。

根据逻辑回归中的代价函数：

$ J(theta) = -frac(1, m) lr([ sum_(i=1)^m y^((i)) log h_theta (x^((i))) + (1 - y^((i))) log(1 - h_theta (x^((i)))) ]) + frac(lambda, 2m) sum_(j=1)^n theta_j^2 $

类似地，神经网络的代价函数(正规化后)为：

$ J(Theta) = &-frac(1, m) lr([ sum_(i=1)^m sum_(k=1)^K y_k^((i)) log(h_Theta (x^((i))))_k + (1 - y_k^((i))) log(1 - (h_Theta (x^((i))))_k) ]) \
&+ frac(lambda, 2m) sum_(l=1)^(L-1) sum_(i=1)^(S_l) sum_(j=1)^(S_(l+1)) (Theta_(j i)^((l)))^2 $

*注意：此处的正规化项中的 $Theta$ 不包含每层和偏置单元相连的权值，即 $Theta^((l))$ 矩阵中的第一列。*

有了代价函数，为了利用梯度下降等方法对 $Theta$ 进行更新，我们还需要求得各个 $Theta$ 分量的偏导数，即：

$ frac(partial, partial Theta_(i j)^((l))) J(Theta) $

要想计算偏导数，给定下面的神经网络：

// Image: Neural network diagram (http://7vztwe.com1.z0.glb.clouddn.com/20170512149457918939786.jpg)

给定一条训练样本 $(x, y)$，首先需要计算 $h_Theta (x)$ (即 *前向传播(Forward propagation)*)：

$ a^((1)) &= x \
z^((2)) &= Theta^((1)) a^((1)) \
a^((2)) &= g(z^((2))) quad ("add" a_0^((2))) \
z^((3)) &= Theta^((2)) a^((2)) \
a^((3)) &= g(z^((3))) quad ("add" a_0^((3))) \
z^((4)) &= Theta^((3)) a^((3)) \
a^((4)) &= h_Theta (x) = g(z^((4))) $

计算出 $h_Theta (x)$ 后，我们就可以使用 *反向传播算法(Back propagation)* 来计算偏导数了。引入 *误差值(error)* 的概念，对于输出层来说：

$ delta^((4)) = a^((4)) - y $

依此类推，向输入层的方向计算各层的误差值：

$ delta^((3)) &= (Theta^((3)))^T delta^((4)) dot.circle g'(z^((3))), quad g'(z^((3))) = a^((3)) dot.circle (1 - a^((3))) \
delta^((2)) &= (Theta^((2)))^T delta^((3)) dot.circle g'(z^((2))) $

对于每个样例 $(x, y)$，反向传播算法的流程如下：

- 设 $Delta_(i j)^((l)) = 0$
- 令 $a^((1)) = x$
- 利用前向传播为后面的每一层 $l = 2, 3, ..., L$ 计算 $a^((l))$
- 计算输出层的误差值 $delta^((L)) = a^((L)) - y$
- 计算前面 *除了输入层* 外每一层的误差值 $delta^((l)) quad (l = 2, 3, ..., L-1)$
- $Delta_(i j)^((l)) = Delta_(i j)^((l)) + a_j^((l)) delta_i^((l+1))$

此时的 $frac(1, m) Delta_(i j)^((l))$ 就是偏导数 $frac(partial, partial Theta_(i j)^((l))) J(Theta)$(未正规化)。

对其进行正规化后的形式为：

$ cases(
  D_(i j)^((l)) = frac(1, m) Delta_(i j)^((l)) + lambda Theta_(i j)^((l)) &quad "if" j != 0,
  D_(i j)^((l)) = frac(1, m) Delta_(i j)^((l)) &quad "if" j = 0,
) $

最终偏导数为：

$ frac(partial, partial Theta_(i j)^((l))) J(Theta) = D_(i j)^((l)) $

至此，神经网络的训练及使用方法就讲完了。在用 Matlab 实现的过程中，由于其自带的迭代函数`fminunc(@costFun, initialTheta, options)`中的`initialTheta`，以及需要的代价函数中的`gradientVec`被要求是向量形式，但是在神经网络计算的 $Theta$、$D^((l))$ 都是矩阵，因此需要将其转换为一维形式：

```
% 转换为一维向量
thetaVec = [Theta1(:); Theta2(:); Theta3(:)];
DVec = [D1(:); D2(:); D3(:)];

% 转换回矩阵形式
Theta1 = reshape(thetaVec(1:x1*y1), row1, col1);
Theta1 = reshape(thetaVec(x1*y1+1:x2*y2), row2, col2);
Theta1 = reshape(thetaVec(x2*y2+1:x3*y3), row3, col3);
```

为了保证你实现的反向传播算法是对的，我们可以将实现的算法计算出的偏导数同用从定义实现的偏导数结果进行比较...导数的定义公式为：

$ frac(partial, partial theta) J(theta) = frac(J(theta + epsilon) - J(theta - epsilon), 2 epsilon) $

对于 $theta = [theta_1, theta_2, ..., theta_n]$，你需要计算每个 $theta_n$ 的偏导数：

$ frac(partial, partial theta_1) J(theta) &= frac(J(theta_1 + epsilon, theta_2, ..., theta_n) - J(theta_1 - epsilon, theta_2, ..., theta_n), 2 epsilon) \
frac(partial, partial theta_2) J(theta) &= frac(J(theta_1, theta_2 + epsilon, ..., theta_n) - J(theta_1, theta_2 - epsilon, ..., theta_n), 2 epsilon) \
&dots.v \
frac(partial, partial theta_n) J(theta) &= frac(J(theta_1, theta_2, ..., theta_n + epsilon) - J(theta_1, theta_2, ..., theta_n - epsilon), 2 epsilon) $

之后将其与由反向传播计算出的偏导数相比较，两者应非常接近。这个方法叫做 *梯度检测(Gradient checking)*

在神经网络中，权值不能全部初始化为0...因此需要 *随机赋值(Random initialization)*...

具体方法：将每个 $Theta_(i j)^((l))$ 随机赋值到 $[-epsilon, epsilon]$ 区间内，在Matlab中实现如下：

```
Theta1 = rand(row1, col1)*(2*INIT_EPSILON) - INIT_EPSILON
Theta2 = rand(row2, col2)*(2*INIT_EPSILON) - INIT_EPSILON
```

总结一下，实现一个神经网络的步骤是：

+ 随机初始化权值矩阵 $Theta$
+ 实现前向传播来计算假设函数 $h_Theta (x)$
+ 实现函数计算代价函数 $J(Theta)$
+ 实现反向传播来计算偏导数 $frac(partial, partial Theta_(i j)^((l))) J(Theta)$
+ 使用梯度检测方法验证自己实现的反向传播算法是否正确
+ 使用梯度下降等算法最小化代价函数 $J(Theta)$ 的值(即训练 $Theta$)
