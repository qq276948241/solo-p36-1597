# 设备借用管理系统 API 文档

## 项目简介

面向公司内部公用设备（笔记本、投影仪、相机等）的借用管理系统，解决 Excel 登记模式下设备冲突、借用期限混乱等问题。核心功能包括设备状态锁定、借用期限管理、逾期自动告警。

## 技术栈

| 层次 | 技术选型 | 说明 |
|------|---------|------|
| Web 框架 | Sinatra | 轻量级 Ruby Web 框架，替代 Rails 避免过重 |
| ORM | Sequel | 灵活高效的 Ruby ORM，比 ActiveRecord 更轻 |
| 数据库 | SQLite | 小型团队足够使用，零配置 |
| 鉴权 | JWT | 无状态 Token 认证 |
| 密码加密 | BCrypt | 安全的密码哈希算法 |
| 应用服务器 | Puma | 高性能 Ruby Web 服务器 |

---

## 通用说明

- **Base URL**: `http://your-host:port/api`
- **Content-Type**: 所有 POST/PUT 请求必须使用 `application/json`
- **鉴权方式**: 需要登录的接口在 Header 中携带 `Authorization: Bearer <token>`
- **角色说明**:
  - `employee` — 普通员工，可借用/归还设备、查询自己的记录
  - `admin` — 管理员，可管理设备、查看所有借用记录、催缴逾期

### 预置测试账号

| 用户名 | 密码 | 角色 |
|--------|------|------|
| admin | admin123 | 管理员 |
| zhangsan | 123456 | 普通员工 |
| lisi | 123456 | 普通员工 |

### HTTP 状态码

| 状态码 | 说明 |
|--------|------|
| 200 | 请求成功 |
| 201 | 创建成功 |
| 400 | 参数错误 / 业务逻辑错误 |
| 401 | 未登录 / Token 无效 |
| 403 | 无权限 / 越权操作 |
| 404 | 资源不存在 |

---

## 一、用户模块

### 1.1 用户注册

**POST** `/api/users/register`

- **权限**: 公开
- **请求体**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| username | string | 是 | 用户名，唯一 |
| password | string | 是 | 密码 |
| name | string | 是 | 真实姓名 |
| role | string | 否 | 角色，`employee`(默认) 或 `admin` |

**响应示例** (201):
```json
{
  "message": "注册成功",
  "token": "eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxLCJleHAiOjE3ODIzMTI4MDB9.xxx",
  "user": {
    "id": 1,
    "username": "wangwu",
    "name": "王五",
    "role": "employee"
  }
}
```

---

### 1.2 用户登录

**POST** `/api/users/login`

- **权限**: 公开
- **请求体**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| username | string | 是 | 用户名 |
| password | string | 是 | 密码 |

**响应示例** (200):
```json
{
  "message": "登录成功",
  "token": "eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxLCJleHAiOjE3ODIzMTI4MDB9.xxx",
  "user": {
    "id": 2,
    "username": "zhangsan",
    "name": "张三",
    "role": "employee"
  }
}
```

---

### 1.3 获取当前用户信息

**GET** `/api/users/me`

- **权限**: 登录用户
- **请求头**: `Authorization: Bearer <token>`

**响应示例** (200):
```json
{
  "user": {
    "id": 2,
    "username": "zhangsan",
    "name": "张三",
    "role": "employee"
  }
}
```

---

### 1.4 获取所有用户

**GET** `/api/users`

- **权限**: 管理员
- **请求头**: `Authorization: Bearer <admin-token>`

**响应示例** (200):
```json
{
  "users": [
    { "id": 1, "username": "admin", "name": "管理员", "role": "admin" },
    { "id": 2, "username": "zhangsan", "name": "张三", "role": "employee" },
    { "id": 3, "username": "lisi", "name": "李四", "role": "employee" }
  ]
}
```

---

### 1.5 获取单个用户详情

**GET** `/api/users/:id`

- **权限**: 管理员
- **路径参数**: `id` — 用户ID

**响应示例** (200):
```json
{
  "user": {
    "id": 2,
    "username": "zhangsan",
    "name": "张三",
    "role": "employee"
  }
}
```

---

## 二、设备管理

### 2.1 获取设备列表

**GET** `/api/devices`

- **权限**: 登录用户
- **查询参数**（均可选，可组合）:

| 参数 | 类型 | 说明 |
|------|------|------|
| type | string | 按设备类型筛选，如 `笔记本`、`投影仪`、`相机` |
| status | string | 按状态筛选：`available`（可用）或 `borrowed`（借出中） |

**响应示例** (200):
```json
{
  "devices": [
    {
      "id": 1,
      "name": "ThinkPad X1 Carbon",
      "equipment_type": "笔记本",
      "device_model": "X1 Carbon Gen 10",
      "serial_number": "NB-2024-001",
      "description": "14寸商务笔记本",
      "status": "available"
    },
    {
      "id": 2,
      "name": "MacBook Pro 14",
      "equipment_type": "笔记本",
      "device_model": "M3 Pro",
      "serial_number": "NB-2024-002",
      "description": "苹果开发本",
      "status": "borrowed"
    }
  ],
  "count": 2
}
```

---

### 2.2 获取所有设备类型

**GET** `/api/devices/types`

- **权限**: 登录用户

**响应示例** (200):
```json
{
  "types": ["笔记本", "投影仪", "相机", "平板"]
}
```

---

### 2.3 获取设备详情

**GET** `/api/devices/:id`

- **权限**: 登录用户
- **路径参数**: `id` — 设备ID
- **说明**: 若设备正在借出中，会附带 `current_borrow` 字段显示当前借用人

**响应示例**（借出中设备, 200）:
```json
{
  "device": {
    "id": 5,
    "name": "Canon EOS R6",
    "equipment_type": "相机",
    "device_model": "EOS R6 Mark II",
    "serial_number": "CAM-2024-001",
    "description": "全画幅微单",
    "status": "borrowed",
    "current_borrow": {
      "id": 2,
      "user_id": 2,
      "user_name": "张三",
      "device_id": 5,
      "device_name": "Canon EOS R6",
      "borrowed_at": "2026-06-20T09:00:00+08:00",
      "expected_return_date": "2026-06-22",
      "returned_at": null,
      "borrow_days": null,
      "status": "borrowed",
      "purpose": "产品宣传拍摄",
      "overdue": true,
      "overdue_days": 2
    }
  }
}
```

---

### 2.4 新增设备

**POST** `/api/devices`

- **权限**: 管理员
- **请求体**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| name | string | 是 | 设备名称 |
| equipment_type | string | 是 | 设备类型 |
| model | string | 否 | 型号 |
| serial_number | string | 否 | 序列号（唯一） |
| description | string | 否 | 描述 |

**响应示例** (201):
```json
{
  "message": "设备创建成功",
  "device": {
    "id": 7,
    "name": "iPad Pro 12.9",
    "equipment_type": "平板",
    "device_model": "M2",
    "serial_number": "TAB-2024-001",
    "description": "12.9寸平板，用于客户展示",
    "status": "available"
  }
}
```

---

### 2.5 更新设备

**PUT** `/api/devices/:id`

- **权限**: 管理员
- **路径参数**: `id` — 设备ID
- **请求体**: 字段同 POST，全部可选，只传需要更新的字段

**响应示例** (200):
```json
{
  "message": "设备更新成功",
  "device": {
    "id": 7,
    "name": "iPad Pro 12.9",
    "equipment_type": "平板",
    "device_model": "M4",
    "serial_number": "TAB-2024-001",
    "description": "12.9寸平板，用于客户展示（已升级M4）",
    "status": "available"
  }
}
```

---

### 2.6 删除设备

**DELETE** `/api/devices/:id`

- **权限**: 管理员
- **路径参数**: `id` — 设备ID
- **约束**: 设备正在借用中不可删除

**响应示例** (200):
```json
{
  "message": "设备删除成功"
}
```

---

## 三、借用流程

### 3.1 获取当前借出清单

**GET** `/api/borrows/current`

- **权限**: 登录用户
- **说明**: 返回所有状态为 `borrowed` 的借用记录，已逾期的自动标记 `overdue: true` 并附 `overdue_days`

**响应示例** (200):
```json
{
  "borrows": [
    {
      "id": 2,
      "user_id": 2,
      "user_name": "张三",
      "device_id": 5,
      "device_name": "Canon EOS R6",
      "borrowed_at": "2026-06-20T09:00:00+08:00",
      "expected_return_date": "2026-06-22",
      "returned_at": null,
      "borrow_days": null,
      "status": "borrowed",
      "purpose": "产品宣传拍摄",
      "overdue": true,
      "overdue_days": 2
    },
    {
      "id": 3,
      "user_id": 3,
      "user_name": "李四",
      "device_id": 1,
      "device_name": "ThinkPad X1 Carbon",
      "borrowed_at": "2026-06-23T10:00:00+08:00",
      "expected_return_date": "2026-06-30",
      "returned_at": null,
      "borrow_days": null,
      "status": "borrowed",
      "purpose": "客户拜访演示",
      "overdue": false
    }
  ],
  "count": 2
}
```

---

### 3.2 获取逾期未还清单

**GET** `/api/borrows/overdue`

- **权限**: 管理员
- **说明**: 返回所有已逾期但未归还的记录，按预计归还日期正序排列（最久的在前），便于管理员催缴

**响应示例** (200):
```json
{
  "borrows": [
    {
      "id": 2,
      "user_id": 2,
      "user_name": "张三",
      "device_id": 5,
      "device_name": "Canon EOS R6",
      "borrowed_at": "2026-06-20T09:00:00+08:00",
      "expected_return_date": "2026-06-22",
      "returned_at": null,
      "borrow_days": null,
      "status": "borrowed",
      "purpose": "产品宣传拍摄",
      "overdue": true,
      "overdue_days": 2
    }
  ],
  "count": 1
}
```

---

### 3.3 我的借用历史

**GET** `/api/borrows/my`

- **权限**: 登录用户
- **说明**: 返回当前用户的所有借用记录，按借用时间倒序排列

**响应示例** (200):
```json
{
  "borrows": [
    {
      "id": 2,
      "user_id": 2,
      "user_name": "张三",
      "device_id": 5,
      "device_name": "Canon EOS R6",
      "borrowed_at": "2026-06-20T09:00:00+08:00",
      "expected_return_date": "2026-06-22",
      "returned_at": null,
      "borrow_days": null,
      "status": "borrowed",
      "purpose": "产品宣传拍摄",
      "overdue": true,
      "overdue_days": 2
    },
    {
      "id": 1,
      "user_id": 2,
      "user_name": "张三",
      "device_id": 1,
      "device_name": "ThinkPad X1 Carbon",
      "borrowed_at": "2026-05-19T23:35:40+08:00",
      "expected_return_date": "2026-06-18",
      "returned_at": "2026-06-24T09:00:00+08:00",
      "borrow_days": 36,
      "status": "returned",
      "purpose": "客户项目演示"
    }
  ],
  "count": 2
}
```

---

### 3.4 获取所有借用记录

**GET** `/api/borrows`

- **权限**: 管理员
- **查询参数**（均可选，可组合）:

| 参数 | 类型 | 说明 |
|------|------|------|
| status | string | `borrowed` 或 `returned` |
| user_id | integer | 指定用户ID |
| device_id | integer | 指定设备ID |

**响应示例** (200):
```json
{
  "borrows": [
    {
      "id": 1,
      "user_id": 2,
      "user_name": "张三",
      "device_id": 1,
      "device_name": "ThinkPad X1 Carbon",
      "borrowed_at": "2026-05-19T23:35:40+08:00",
      "expected_return_date": "2026-06-18",
      "returned_at": "2026-06-24T09:00:00+08:00",
      "borrow_days": 36,
      "status": "returned",
      "purpose": "客户项目演示"
    },
    {
      "id": 2,
      "user_id": 2,
      "user_name": "张三",
      "device_id": 5,
      "device_name": "Canon EOS R6",
      "borrowed_at": "2026-06-20T09:00:00+08:00",
      "expected_return_date": "2026-06-22",
      "returned_at": null,
      "borrow_days": null,
      "status": "borrowed",
      "purpose": "产品宣传拍摄",
      "overdue": true,
      "overdue_days": 2
    }
  ],
  "count": 2
}
```

---

### 3.5 获取借用记录详情

**GET** `/api/borrows/:id`

- **权限**: 登录用户
- **路径参数**: `id` — 借用记录ID
- **约束**: 普通员工只能查看自己的借用记录，管理员可查看全部

**响应示例** (200):
```json
{
  "borrow": {
    "id": 2,
    "user_id": 2,
    "user_name": "张三",
    "device_id": 5,
    "device_name": "Canon EOS R6",
    "borrowed_at": "2026-06-20T09:00:00+08:00",
    "expected_return_date": "2026-06-22",
    "returned_at": null,
    "borrow_days": null,
    "status": "borrowed",
    "purpose": "产品宣传拍摄",
    "overdue": true,
    "overdue_days": 2
  }
}
```

---

### 3.6 提交借用申请

**POST** `/api/borrows`

- **权限**: 登录用户
- **请求体**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| device_id | integer | 是 | 要借用的设备ID |
| expected_return_date | string | 是 | 预计归还日期，格式 `YYYY-MM-DD`，必须晚于今天 |
| purpose | string | 否 | 借用用途 |

- **约束**: 设备状态必须为 `available`，否则会拒绝借用（防冲突）

**响应示例** (201):
```json
{
  "message": "借用申请成功",
  "borrow": {
    "id": 4,
    "user_id": 3,
    "user_name": "李四",
    "device_id": 7,
    "device_name": "iPad Pro 12.9",
    "borrowed_at": "2026-06-24T10:00:00+08:00",
    "expected_return_date": "2026-07-10",
    "returned_at": null,
    "borrow_days": null,
    "status": "borrowed",
    "purpose": "客户产品展示",
    "overdue": false
  }
}
```

---

### 3.7 确认归还

**POST** `/api/borrows/:id/return`

- **权限**: 登录用户
- **路径参数**: `id` — 借用记录ID
- **约束**:
  - 只能归还自己借用的设备，管理员可代还
  - 设备已归还则重复调用会报错
- **自动计算**: `borrow_days` 自动计算，不足1天按1天算

**响应示例** (200):
```json
{
  "message": "设备归还成功",
  "borrow_days": 4,
  "borrow": {
    "id": 2,
    "user_id": 2,
    "user_name": "张三",
    "device_id": 5,
    "device_name": "Canon EOS R6",
    "borrowed_at": "2026-06-20T09:00:00+08:00",
    "expected_return_date": "2026-06-22",
    "returned_at": "2026-06-24T10:05:00+08:00",
    "borrow_days": 4,
    "status": "returned",
    "purpose": "产品宣传拍摄"
  }
}
```

---

### 3.8 删除借用记录

**DELETE** `/api/borrows/:id`

- **权限**: 管理员
- **路径参数**: `id` — 借用记录ID
- **说明**: 如果设备仍在借出中，删除时会自动将设备状态恢复为 `available`

**响应示例** (200):
```json
{
  "message": "借用记录删除成功"
}
```

---

## 四、状态流转说明

```
设备状态:
  available ──[借用申请]──> borrowed ──[确认归还]──> available
               (防重复借)           (自动算天数)

借用记录状态:
  borrowed  ──[归还]──> returned
```

## 五、核心业务规则

1. **设备锁定**: 设备被借出后状态变为 `borrowed`，其他人无法重复借用，直到归还
2. **预计归还日期**: 借用时必填，格式 `YYYY-MM-DD`，且必须晚于当日
3. **逾期判定**: 预计归还日期 < 今日 且 状态为 `borrowed`，即为逾期
4. **借用天数**: 不足1天按1天计算，公式 `(returned_at - borrowed_at).ceil.to_i`
5. **权限隔离**: 普通员工只能操作自己的记录，管理员拥有全部权限
