CREATE DATABASE IF NOT EXISTS stu_lecture DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;

USE stu_lecture;

-- 1. 用户表
CREATE TABLE users (
    user_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL COMMENT '登录账号',
    password VARCHAR(255) NOT NULL COMMENT '密码',
    role ENUM('admin', 'teacher', 'student') NOT NULL COMMENT '用户角色',
    name VARCHAR(50) NOT NULL COMMENT '姓名',
    email VARCHAR(100) COMMENT '邮箱',
    phone VARCHAR(20) COMMENT '电话',
    department VARCHAR(100) COMMENT '院系',
    major VARCHAR(100) COMMENT '专业/研究方向',
    grade VARCHAR(20) COMMENT '年级',
    avatar VARCHAR(255) COMMENT '用户头像路径',
    bio TEXT COMMENT '个人简介',
    position VARCHAR(100) COMMENT '职位',
    status TINYINT(1) DEFAULT 0 COMMENT '状态：0-未激活 1-启用 -1-禁用',
    created_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    -- 索引说明：
    -- idx_role: 按角色快速筛选用户
    -- idx_status: 按状态过滤有效用户
    INDEX idx_role (role),
    INDEX idx_status (status)
) COMMENT='用户信息表';

-- 插入测试用户数据
-- 密码均为: 123456 (明文)
INSERT INTO users (username, password, role, name, email, phone, department, major, grade, status) VALUES
('admin', '123456', 'admin', '系统管理员', 'admin@university.edu.cn', '13800000001', '教务处', NULL, NULL, 1),
('teacher01', '123456', 'teacher', '张教授', 'teacher01@university.edu.cn', '13800000002', '计算机学院', '软件工程', NULL, 1),
('student01', '123456', 'student', '李同学', 'student01@university.edu.cn', '13800000003', '计算机学院', '计算机科学与技术', '2024', 1);

-- 2. 讲座表
CREATE TABLE lectures (
    lecture_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(100) NOT NULL COMMENT '讲座标题',
    speaker_id BIGINT NOT NULL COMMENT '主讲人 ID',
    description TEXT COMMENT '讲座简介',
    poster VARCHAR(255) COMMENT '海报图片路径',
    lecture_time DATETIME NOT NULL COMMENT '举办时间',
    location VARCHAR(100) NOT NULL COMMENT '地点',
    capacity INT NOT NULL COMMENT '容量',
    enrolled_count INT DEFAULT 0 COMMENT '已预约人数',
    status ENUM('pending', 'approved', 'expired') DEFAULT 'pending' COMMENT '状态：pending-待审核 approved-已通过 expired-已失效',
    category VARCHAR(50) COMMENT '科目',
    duration INT COMMENT '讲座时长 (分钟)',
    format ENUM('offline', 'online') COMMENT '讲座形式：offline-线下 online-线上',
    notice TEXT COMMENT '注意事项',
    venue_id BIGINT COMMENT '场地ID',
    created_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (speaker_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (venue_id) REFERENCES venues(venue_id) ON DELETE SET NULL,
    -- 索引说明：
    -- idx_speaker: 快速查找某讲师的所有讲座
    -- idx_time: 按时间排序和范围查询
    -- idx_status: 筛选特定状态的讲座
    INDEX idx_speaker (speaker_id),
    INDEX idx_time (lecture_time),
    INDEX idx_status (status)
) COMMENT='讲座信息表';

-- 3. 预约表
CREATE TABLE reservations (
    reservation_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL COMMENT '预约用户 ID',
    lecture_id BIGINT NOT NULL COMMENT '讲座 ID',
    status ENUM('confirmed', 'cancelled') DEFAULT 'confirmed' COMMENT '预约状态',
    reminded_1day BOOLEAN DEFAULT FALSE COMMENT '是否已发送1天提醒',
    reminded_2hours BOOLEAN DEFAULT FALSE COMMENT '是否已发送2小时提醒',
    apply_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (lecture_id) REFERENCES lectures(lecture_id) ON DELETE CASCADE,
    -- 索引说明：
    -- uk_user_lecture: 防止重复预约（唯一约束）
    -- idx_user: 查询某用户的所有预约
    -- idx_lecture: 查询某讲座的所有预约
    -- idx_status: 筛选特定状态的预约
    UNIQUE KEY uk_user_lecture (user_id, lecture_id),
    INDEX idx_user (user_id),
    INDEX idx_lecture (lecture_id),
    INDEX idx_status (status)
) COMMENT='预约记录表';

-- 4. 场地表
CREATE TABLE venues (
    venue_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL COMMENT '场地名称',
    capacity INT NOT NULL COMMENT '容纳人数',
    location VARCHAR(200) COMMENT '位置',
    status TINYINT DEFAULT 1 COMMENT '状态：1 可用 0 维护',
    created_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    -- 索引说明：
    -- idx_status: 快速筛选可用场地
    INDEX idx_status (status)
) COMMENT='场地信息表';

-- 5. 通知表
CREATE TABLE notifications (
    notification_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(200) NOT NULL COMMENT '通知标题',
    content TEXT NOT NULL COMMENT '通知内容',
    type ENUM('system', 'lecture', 'reservation', 'reminder') NOT NULL COMMENT '通知类型',
    receiver_id BIGINT NOT NULL COMMENT '接收者 ID',
    sender_id BIGINT COMMENT '发送者 ID（系统通知为 NULL）',
    status ENUM('unread', 'read') DEFAULT 'unread' COMMENT '阅读状态',
    send_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '发送时间',
    read_time TIMESTAMP NULL COMMENT '阅读时间',
    FOREIGN KEY (receiver_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (sender_id) REFERENCES users(user_id) ON DELETE SET NULL,
    -- 索引说明：
    -- idx_receiver: 查询某用户收到的通知
    -- idx_status: 筛选未读/已读通知
    -- idx_send_time: 按发送时间排序
    -- idx_type: 按类型筛选
    INDEX idx_receiver (receiver_id),
    INDEX idx_status (status),
    INDEX idx_send_time (send_time),
    INDEX idx_type (type)
) COMMENT='通知消息表';

-- 5.1 通知模板表（管理员配置）
CREATE TABLE notification_templates (
    template_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    template_name VARCHAR(100) NOT NULL COMMENT '模板名称',
    type ENUM('system', 'lecture', 'reservation', 'reminder') NOT NULL COMMENT '通知类型',
    scene VARCHAR(50) NOT NULL COMMENT '使用场景：audit_approved/audit_rejected/reservation_success/reminder_before_start',
    title_template VARCHAR(200) NOT NULL COMMENT '标题模板，支持变量：{lectureTitle}, {userName} 等',
    content_template TEXT NOT NULL COMMENT '内容模板，支持变量',
    is_enabled TINYINT DEFAULT 1 COMMENT '是否启用：0-否 1-是',
    created_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_type_scene (type, scene)
) COMMENT='通知模板表';

-- 插入默认通知模板
INSERT INTO notification_templates (template_name, type, scene, title_template, content_template, is_enabled) VALUES
('讲座审核通过', 'lecture', 'lecture.audit_approved', '讲座《{lectureTitle}》已通过审核', '您的讲座《{lectureTitle}》已通过审核，将于 {lectureTime} 在 {location} 举行。请做好相关准备。', 1),
('讲座审核拒绝', 'lecture', 'lecture.audit_rejected', '讲座《{lectureTitle}》未通过审核', '很遗憾，您的讲座《{lectureTitle}》未通过审核。原因：{rejectReason}。请修改后重新提交。', 1),
('预约成功通知', 'reservation', 'reservation.reservation_success', '预约成功：{lectureTitle}', '您已成功预约讲座《{lectureTitle}》，举办时间：{lectureTime}，地点：{location}。请准时参加！', 1),
('预约取消通知', 'reservation', 'reservation.reservation_cancelled', '预约已取消：{lectureTitle}', '您预约的讲座《{lectureTitle}》已被取消。{reason}', 1),
('讲座开始提醒', 'reminder', 'reminder_less_1day', '【即将开始】讲座《{lectureTitle}》', '温馨提醒：您预约的讲座《{lectureTitle}》将于 {lectureTime} 在 {location} 举行，请提前安排好时间。', 1),
('讲座开始提醒', 'reminder', 'reminder_less_2hours', '【即将开始】讲座《{lectureTitle}》', '最后提醒：您预约的讲座《{lectureTitle}》将在不到2小时内开始，地点：{location}。请准时参加！', 1),
('预约满员通知', 'lecture', 'lecture.full', '恭喜！讲座《{lectureTitle}》预约已满', '恭喜！您的讲座《{lectureTitle}》预约人数已满（{capacity}人）。感谢您的精彩分享！', 1),
('讲座变更通知', 'lecture', 'lecture.changed', '讲座《{lectureTitle}》信息变更', '您关注的讲座《{lectureTitle}》信息发生变更，请相互转告，准时参加！', 1),
('讲座取消通知', 'lecture', 'lecture_cancelled_by_admin', '讲座《{lectureTitle}》已被取消', '很抱歉，讲座《{lectureTitle}》已被管理员取消。请相互转告，给您带来不便，深表歉意！', 1);

-- 6. 操作日志表
CREATE TABLE operation_logs (
    log_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT COMMENT '操作用户ID',
    username VARCHAR(50) COMMENT '用户名',
    operation VARCHAR(100) NOT NULL COMMENT '操作描述',
    module VARCHAR(50) NOT NULL COMMENT '功能模块',
    description TEXT COMMENT '详细说明',
    create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- 索引说明：
    -- idx_user: 查询某用户的所有操作
    -- idx_module: 按功能模块统计
    -- idx_time: 时间范围查询
    INDEX idx_user (user_id),
    INDEX idx_module (module),
    INDEX idx_time (create_time)
) COMMENT='操作日志表';
