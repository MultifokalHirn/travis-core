class StarredRepositoriesAddIndexUserIdAndRepoId < ActiveRecord::Migration
  self.disable_ddl_transaction!

  def up
    execute "CREATE UNIQUE INDEX index_starred_repositories_on_user_id_and_repo_id ON starred_repositories (user_id, repository_id)"
  end

  def down
    execute "DROP INDEX index_starred_repositories_on_user_id_and_repo_id"
  end
end
