require 'test_helper'

class FilesControllerTest < ActionController::TestCase
  test "should get process" do
    get :process
    assert_response :success
  end

  test "should get show" do
    get :show
    assert_response :success
  end

end
