RSpec.describe 'Fauna Util' do
  describe '#time_from_usecs' do
    it 'converts microseconds to time' do
      time = Time.at(1, 234_567)
      usecs = 1_234_567

      expect(Fauna.time_from_usecs(usecs)).to eq(time)
    end
  end

  describe '#usecs_from_time' do
    it 'converts time to microseconds' do
      time = Time.at(1, 234_567)
      usecs = 1_234_567

      expect(Fauna.usecs_from_time(time)).to eq(usecs)
    end
  end
end
