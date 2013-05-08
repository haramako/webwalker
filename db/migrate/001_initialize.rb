class Initialize < ActiveRecord::Migration

  def self.up

    create_table :projects, :options => 'DEFAULT CHARSET=utf8' do |t|
      t.column :url, :string, null: false
      t.column :name, :string, null: false
      t.column :plugin, :string, null: false
      t.column :status, :string, null: false, length:1, default:''
      t.column :url_all, :integer, null: false, default:0
      t.column :url_finished, :integer, null: false, default:0
      t.column :url_failed, :integer, null: false, default:0
      t.column :zipped_at, :datetime
      t.timestamps
    end
    add_index :projects, :url, unique: true
    add_index :projects, :name

    create_table :urls do |t|
      t.column :project_id, :integer, null: false
      t.column :url, :string, null: false
      t.column :expire_at, :datetime, null:false
      t.column :status, :string, null: false, length:1, default:''
      t.timestamps
    end
    add_index :urls, [:project_id, :url], unique:true
    add_index :urls, :url
    add_index :urls, [:status, :expire_at]
    add_index :urls, :project_id

  end

  def self.down
    drop_table :urls
    drop_table :projects
  end

end
