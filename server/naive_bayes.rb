require 'yaml'
require 'stemmer'
require 'classifier'
require 'sinatra'

def initialize_classifiers
  training = YAML::load_file('training.yml')
  classifiers = Hash.new
  training['cultures'].each do |culture|
    classifier = (classifiers[culture['name']] = Classifier::Bayes.new)
    culture['categories'].each do |category|
      classifier.add_category category['name']
      category['training'].each do |train_text|
        classifier.train category['name'], train_text
      end
    end
  end
  return classifiers
end

get '/analyze/:culture/:text' do
  @classifiers = initialize_classifiers
  @classification = @classifiers[params[:culture]]
  result = (@classification.classifications params[:text]).inspect
  result += " " + (@classification.classify params[:text]).inspect
end
