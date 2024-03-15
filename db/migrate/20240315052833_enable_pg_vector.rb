class EnablePgVector < ActiveRecord::Migration[7.1]
  def change
    enable_extension 'vector'
  end
end
