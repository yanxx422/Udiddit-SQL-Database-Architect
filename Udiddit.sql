DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS topics CASCADE;
DROP TABLE IF EXISTS posts CASCADE;
DROP TABLE IF EXISTS comments CASCADE;
DROP TABLE IF EXISTS votes CASCADE;

CREATE TABLE users (
	id SERIAL PRIMARY KEY,
  	user_name VARCHAR(25) UNIQUE NOT NULL,
  	recent_login_time TIMESTAMP
);

CREATE UNIQUE INDEX "find_user_by_name" ON "users" ("user_name");
CREATE INDEX "find_user_by_login_time" ON "users" ("recent_login_time");

  
CREATE TABLE topics (
	id SERIAL PRIMARY KEY,
  	topic_name VARCHAR(30) UNIQUE NOT NULL ,
	user_id BIGINT REFERENCES users,
  	description VARCHAR(500)
);

CREATE TABLE posts (
	id SERIAL PRIMARY KEY,
  	title VARCHAR(100) NOT NULL,
  	url VARCHAR(4000),
  	text_content TEXT,
  	user_id BIGINT REFERENCES "users" ON DELETE SET NULL,
  	topic_id BIGINT REFERENCES "topics" ON DELETE CASCADE,
	score BIGINT,
  	CONSTRAINT only_one_value CHECK (("url" is NULL OR "text_content" is NULL) 
				   AND NOT ("url" is NULL AND "text_content" is NULL))
);

CREATE INDEX "find_post_by_user" ON "posts" ("user_id");
CREATE INDEX "find_post_by_topic" ON "posts" ("topic_id");
CREATE INDEX "find_post_by_url" ON "posts" ("url");


CREATE TABLE votes (
	id SERIAL PRIMARY KEY,
  	post_id BIGINT REFERENCES "posts" ON DELETE CASCADE NOT NULL,
  	user_id BIGINT REFERENCES "users" ON DELETE SET NULL,
  	vote_value SMALLINT CHECK (vote_value =1 OR vote_value = -1),
	CONSTRAINT "one_vote_per_user" UNIQUE(user_id, post_id)
);


  
CREATE TABLE comments (
	id SERIAL PRIMARY KEY,
  	post_id BIGINT REFERENCES "posts" ("id") ON DELETE CASCADE,
  	user_id BIGINT REFERENCES "users" ON DELETE SET NULL,
  	parent_comment_id BIGINT REFERENCES "comments" ("id") ON DELETE CASCADE,
  	text_content TEXT not NULL
);

CREATE INDEX "find_parent_by_children" ON "comments" ("parent_comment_id");






INSERT INTO "topics" ("topic_name")
	SELECT DISTINCT "topic" FROM "bad_posts";


    
INSERT INTO "users" ("user_name")
	SELECT DISTINCT "username" FROM "bad_posts";
    
INSERT INTO "users" ("user_name") 
    	SELECT  "username" AS name  FROM "bad_comments"
    	WHERE 
    	NOT EXISTS (SELECT "user_name" 
                FROM users);
    
    

    
INSERT INTO "users" ("user_name")  
    	SELECT DISTINCT REGEXP_SPLIT_TO_TABLE(downvotes,',') FROM "bad_posts"
    	WHERE 
    	NOT EXISTS (SELECT "user_name" 
                FROM users);
    
INSERT INTO "users" ("user_name")      
    	SELECT DISTINCT REGEXP_SPLIT_TO_TABLE(upvotes,',') FROM "bad_posts"
    	WHERE 
    	NOT EXISTS (SELECT "user_name" 
                FROM users);
                
INSERT INTO "posts" ("title","url","text_content","user_id","topic_id")
	SELECT bad_posts.title,bad_posts.url, bad_posts.text_content,
	users.id,topics.id
	FROM bad_posts
	JOIN users ON bad_posts.username = users.user_name
	JOIN topics ON topics.topic_name = bad_posts.topic
	WHERE LENGTH(bad_posts.title) <= 100 AND length(bad_posts.title) > 0 ;



INSERT INTO "comments" ("text_content","user_id","post_id")
	SELECT bad_comments.text_content,users.id,posts.id 
	FROM bad_comments 
	JOIN users 
	ON bad_comments.username = users.user_name
	JOIN posts 
	ON posts.id = bad_comments.post_id;

CREATE VIEW names AS
	SELECT REGEXP_SPLIT_TO_TABLE(bad_posts.upvotes,',') 
	FROM 
	bad_posts;

CREATE VIEW id_names AS
	SELECT users.id, names.regexp_split_to_table
	FROM users
	JOIN names
	ON names.regexp_split_to_table = users.user_name;
	



INSERT INTO "votes" ("user_id","post_id") 
	SELECT id_names.id, posts.id FROM users 
	JOIN id_names 
	ON users.user_name = id_names.regexp_split_to_table
	JOIN posts
	ON posts.user_id = id_names.id;
	




	

UPDATE "votes" SET vote_value = 1;




CREATE VIEW down_vote_names AS
	SELECT REGEXP_SPLIT_TO_TABLE(bad_posts.downvotes,',') 
	FROM bad_posts;

CREATE VIEW id_down_vote_names AS
	SELECT users.id, down_vote_names.regexp_split_to_table
	FROM users
	JOIN down_vote_names
	ON down_vote_names.regexp_split_to_table = users.user_name;

INSERT INTO "votes" ("user_id","post_id") 
	SELECT id_down_vote_names.id, posts.id FROM users 
	JOIN id_down_vote_names 
	ON users.user_name = id_down_vote_names.regexp_split_to_table
	JOIN posts
	ON posts.user_id = id_down_vote_names.id;
	

UPDATE "votes" SET vote_value = -1 WHERE vote_value is NULL;




