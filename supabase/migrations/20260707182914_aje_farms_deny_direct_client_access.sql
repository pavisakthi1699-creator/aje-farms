DROP POLICY IF EXISTS deny_direct_client_access ON users;
CREATE POLICY deny_direct_client_access ON users
  FOR ALL TO public
  USING (false)
  WITH CHECK (false);

DROP POLICY IF EXISTS deny_direct_client_access ON otp_challenges;
CREATE POLICY deny_direct_client_access ON otp_challenges
  FOR ALL TO public
  USING (false)
  WITH CHECK (false);

DROP POLICY IF EXISTS deny_direct_client_access ON payment_transactions;
CREATE POLICY deny_direct_client_access ON payment_transactions
  FOR ALL TO public
  USING (false)
  WITH CHECK (false);

DROP POLICY IF EXISTS deny_direct_client_access ON auth_sessions;
CREATE POLICY deny_direct_client_access ON auth_sessions
  FOR ALL TO public
  USING (false)
  WITH CHECK (false);

DROP POLICY IF EXISTS deny_direct_client_access ON learning_progress;
CREATE POLICY deny_direct_client_access ON learning_progress
  FOR ALL TO public
  USING (false)
  WITH CHECK (false);

DROP POLICY IF EXISTS deny_direct_client_access ON notification_settings;
CREATE POLICY deny_direct_client_access ON notification_settings
  FOR ALL TO public
  USING (false)
  WITH CHECK (false);

DROP POLICY IF EXISTS deny_direct_client_access ON notification_devices;
CREATE POLICY deny_direct_client_access ON notification_devices
  FOR ALL TO public
  USING (false)
  WITH CHECK (false);

DROP POLICY IF EXISTS deny_direct_client_access ON notifications;
CREATE POLICY deny_direct_client_access ON notifications
  FOR ALL TO public
  USING (false)
  WITH CHECK (false);

DROP POLICY IF EXISTS deny_direct_client_access ON content_courses;
CREATE POLICY deny_direct_client_access ON content_courses
  FOR ALL TO public
  USING (false)
  WITH CHECK (false);

DROP POLICY IF EXISTS deny_direct_client_access ON content_documents;
CREATE POLICY deny_direct_client_access ON content_documents
  FOR ALL TO public
  USING (false)
  WITH CHECK (false);

DROP POLICY IF EXISTS deny_direct_client_access ON community_posts;
CREATE POLICY deny_direct_client_access ON community_posts
  FOR ALL TO public
  USING (false)
  WITH CHECK (false);

DROP POLICY IF EXISTS deny_direct_client_access ON community_replies;
CREATE POLICY deny_direct_client_access ON community_replies
  FOR ALL TO public
  USING (false)
  WITH CHECK (false);

DROP POLICY IF EXISTS deny_direct_client_access ON reported_community_posts;
CREATE POLICY deny_direct_client_access ON reported_community_posts
  FOR ALL TO public
  USING (false)
  WITH CHECK (false);;
